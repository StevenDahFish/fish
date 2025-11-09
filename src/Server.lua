--[=[
	@class Server

	Contains the server functionality of fish framework
]=]

local RunService = game:GetService("RunService")
local Server = {}

--// Dependencies
local DependencyTypes = require(script.Parent.DependencyTypes)
local ServerComm = require(script.Parent.Parent.Comm).ServerComm
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local Mutex = require(script.Parent.Parent.Mutex)
local fish = require(script.Parent.Types)

--// Constants & Variables
local services: {[string]: fish.Service<any>} = {}
local serviceDirectories: {Instance} = {}
local started = false
local isStarting = false
local startedSignal = Signal.new()

--[=[
	@ignore
	@prop N/A nil
	@within Server
	Markers that identify the type of class they are
]=]
local SIGNAL_MARKER = newproxy(true)
getmetatable(SIGNAL_MARKER).__tostring = function()
	return "SIGNAL_MARKER"
end

local UNRELIABLE_SIGNAL_MARKER = newproxy(true)
getmetatable(UNRELIABLE_SIGNAL_MARKER).__tostring = function()
	return "UNRELIABLE_SIGNAL_MARKER"
end

local PROPERTY_MARKER = newproxy(true)
getmetatable(PROPERTY_MARKER).__tostring = function()
	return "PROPERTY_MARKER"
end

--[=[
	Constructs/gets a service.
	If the service already exists, the existing service will be returned.

	@param name string -- The name of the service
	@param serviceDef fish.ServiceDef<T>? -- The definition of the service
	@param scriptInstance ModuleScript? -- The script instance of the service
	@return fish.Service<T> -- The service itself
]=]
function Server.service<T>(name: string, serviceDef: fish.ServiceDef<T>?, scriptInstance: ModuleScript?): fish.Service<T>
	if serviceDef == nil or services[name] ~= nil then
		-- Get service
		return services[name] :: fish.Service<T>
	else
		-- Construct service
		assert(type(name) == "string", `Name must be a string; got {typeof(name)}`)
		assert(#name > 0, "Name must be a non-empty string")
		assert(type(serviceDef) == "table", `Service must be a table; got {typeof(serviceDef)}`)
		assert(typeof(scriptInstance) == "Instance" and scriptInstance:IsA("ModuleScript"), `Script instance must be provided; got type {typeof(scriptInstance)}`)
		assert(services[name] == nil, `Service "{name}" already exists`)

		if scriptInstance.Parent then
			local loadRequirementModule = scriptInstance.Parent:FindFirstChild("@load")
			if loadRequirementModule ~= nil and loadRequirementModule:IsA("ModuleScript") then
				local shouldLoad = (require)(loadRequirementModule)(scriptInstance)
				if not shouldLoad then
					warn(`Service "{name}" was loaded even though @load indicates not to. Look for any other scripts that are unexpectedly requiring its module.`)
				end
			end
		end

		assert(not started, "Service cannot be added after calling \"fish.Start()\"")

		local service = serviceDef :: fish.InternalServiceDef<T>

		if type(service.Client) ~= "table" then
			service.Client = {}
		end
		assert(service.Client)
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
		if type(service.Client.Signal) == "table" then
			service.Client.Signal.Server = service
		end
		if type(service.Start) ~= "function" then
			service.Start = function()
				return nil
			end
		end
		service.__fishMetadata = {
			Instance = scriptInstance
		}

		services[name] = service :: fish.Service<T>
		return services[name]
	end
end

--[=[
	Constructs all services out of the modules in the descendants in the given instance.
	If the parent of a service module has an "@load" module, it will use it to check whether it should load any service modules in that folder.

	@param folder Instance -- The instance containing the service modules
]=]
function Server.serviceDeep(folder: Instance)
	assert(typeof(folder) == "Instance", `Folder must be an Instance; got {typeof(folder)}`)
	table.insert(serviceDirectories, folder)
	
	local requirePromises: {Promise.Promise} = {}
	for _, object in folder:GetDescendants() do
		if object:IsA("ModuleScript") and object.Name ~= "@load" then
			if object.Parent ~= nil then
				local loadRequirementModule = object.Parent:FindFirstChild("@load")
				if loadRequirementModule ~= nil and loadRequirementModule:IsA("ModuleScript") then
					local shouldLoad = (require)(loadRequirementModule)(object)
					if not shouldLoad then
						continue
					end
				end
			end
			table.insert(requirePromises, Promise.try(require, object):timeout(5, "SERVICE_REQUIRE_TIMEOUT"):catch(function(err)
				if err == "SERVICE_REQUIRE_TIMEOUT" then
					warn(`Service "{object.Name}" took too long to be required, look for an unresolvable dependency.`)
				else
					warn(err)
				end
			end))
		end
	end
	Promise.all(requirePromises):await()
end

--[=[
	Returns a marker that will transform into a RemoteSignal once all services are started.

	@param unreliable boolean? -- Whether this should be an unreliable RemoteSignal
	@return RemoteSignal
]=]
function Server.signal(unreliable: boolean?): DependencyTypes.RemoteSignal
	if unreliable == true then
		return UNRELIABLE_SIGNAL_MARKER
	else
		return SIGNAL_MARKER
	end
end

--[=[
	Returns a marker that will transform into a RemoteProperty once all services are started.

	@return RemoteProperty
]=]
function Server.property(initialValue: any): DependencyTypes.RemoteProperty
	return { PROPERTY_MARKER, initialValue } :: DependencyTypes.RemoteProperty
end

--[=[
	Starts all created services.
	Services cannot be created after called.

	@return Promise<> -- Promise that resolves when started
]=]
function Server.start(): Promise.TypedPromise<>
	if started then
		return Promise.reject("fish is already started")
	elseif isStarting then
		return Promise.reject("fish is already starting")
	else
		isStarting = true
		return Promise.new(function(resolve)
			local servicesFolder = Instance.new("Folder")
			servicesFolder.Name = "Services"
			servicesFolder.Parent = script.Parent

			-- Wrap function to alter parameter functionality with player
			local function wrapFunction<K, V>(func: (...any) -> ())
				local mutex = Mutex.new() :: any -- type definitions are not up-to-date with luau new solver
				return function(self: {[K]: V}, player: Player, ...)
					-- Create a local copy of "self" and inject "player" into it
					local localSelf = {}
					for k, v in self do
						localSelf[k] = v
					end
					localSelf.Player = player

					-- Implement mutex and inject it
					localSelf.Mutex = {
						Lock = function(self: any)
							mutex:Lock()
						end,
						Unlock = function(self: any)
							mutex:Unlock()
						end,
						Wrap = function(self: any, func: (...any) -> (), ...)
							mutex:Lock()
							local results = {pcall(func, ...)}
							mutex:Unlock()
							return unpack(results)
						end
					}

					-- Implement confirm and inject it
					local returnValues: {any} = {"__fish_caught_error", "__fish_unknown_error"}
					localSelf.confirm = function<T>(value: T)
						if not value then
							if coroutine.isyieldable() then
								returnValues = {}
								task.defer(coroutine.close, coroutine.running())
								coroutine.yield()
							else
								error("Unable to silently fail, current thread is not yieldable")
							end
						end
						return value
					end

					-- Call the original function with the modified "localSelf"
					local args = {...}
					local thread = task.spawn(function()
						if RunService:IsStudio() then
							returnValues = {func(localSelf, unpack(args))}
						else
							local success, err = (pcall :: () -> (boolean, string?))(function() -- casting pcall due to luau new solver issue (see #1881)
								returnValues = {func(localSelf, unpack(args))}
							end)
							if not success then
								returnValues[2] = err
								error(err, 2)
							end
						end
					end)
					if coroutine.status(thread) == "dead" then
						return unpack(returnValues)
					else
						repeat task.wait() until coroutine.status(thread) == "dead"
						return unpack(returnValues)
					end
				end
			end

			for name, service in services do
				Promise.try(function()
					-- Register client functionality
					local client = service.Client :: {[any]: any}

					local hasPublicComms = false
					if type(client.Signal) == "table" then
						for k in client.Signal do
							if k == "Server" then
								continue
							end

							hasPublicComms = true
							break
						end
					end
					if not hasPublicComms then
						for k in client do
							if k == "Server" then
								continue
							end
							if k == "Signal" and type(client.Signal) == "table" then
								continue
							end

							hasPublicComms = true
							break
						end
					end
					
					if not hasPublicComms then
						service:Start()
						return
					end

					local comm = ServerComm.new(servicesFolder, name) :: any
					for k, v in client do
						if type(v) == "function" then
							client[k] = wrapFunction(v)
							comm:WrapMethod(service.Client, k)
						elseif v == SIGNAL_MARKER then
							client[k] = comm:CreateSignal(k, false)
						elseif v == UNRELIABLE_SIGNAL_MARKER then
							client[k] = comm:CreateSignal(k, true)
						elseif type(v) == "table" and (v :: {[any]: any})[1] == PROPERTY_MARKER then
							client[k] = comm:CreateProperty(k, (v :: {[any]: any})[2])
						elseif k == "Signal" and type(v) == "table" then
							for sk, sv in v do
								if type(sv) == "function" then
									local wrappedFunction = wrapFunction(sv :: (...any) -> any);
									local signal = comm:CreateSignal(sk, false);
									(v :: {[any]: any})[sk :: any] = signal
									signal:Connect(function(...)
										return wrappedFunction(v :: {[any]: any}, ...)
									end)
								end
							end
						end
					end
					
					-- Emulate structure from construction
					local serviceFolder: Folder = (servicesFolder :: any)[name]
					local serviceScriptInstance: ModuleScript = service.__fishMetadata.Instance
					local rootDirectory: Instance? = serviceScriptInstance
					local parents: {string} = {}
					while true do
						if rootDirectory ~= nil and rootDirectory.Parent ~= nil then
							rootDirectory = rootDirectory.Parent :: Instance
							table.insert(parents, rootDirectory.Name)
							if table.find(serviceDirectories, rootDirectory) ~= nil then
								-- Found root directory
								break
							end
						else
							-- No root directory found
							rootDirectory = nil
							break
						end
					end

					if rootDirectory ~= nil and #parents > 1 then
						-- Reverse parents and remove root directory
						for i = 1, math.floor(#parents / 2) do
							local j = #parents - i + 1
							parents[i], parents[j] = parents[j], parents[i]
						end
						table.remove(parents, 1)
						
						serviceFolder:SetAttribute("Structure", table.concat(parents, "."))
					end

					service.__fishMetadata = nil
					
					service:Start()
				end)
			end
			
			isStarting = false
			started = true
			startedSignal:Fire()
			local startedValue = Instance.new("BinaryStringValue")
			startedValue.Name = "__fishServerStarted"
			startedValue.Parent = script.Parent
			resolve()
		end)
	end
end

--[=[
	Returns a promise that is resolved once services are started.

	@return Promise<> -- Promise that resolves when started
]=]
function Server.onStart(): Promise.TypedPromise<>
	if started then
		return Promise.resolve()
	else
		return Promise.fromEvent(startedSignal) :: Promise.TypedPromise<>
	end
end

return Server