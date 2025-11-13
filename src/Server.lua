--[=[
	@class Server

	Contains the server functionality of fish framework
]=]

local RunService = game:GetService("RunService")
local Server = {}

--// Dependencies
local ServerComm = require(script.Parent.Parent.Comm).ServerComm
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local Types = require(script.Parent.Types)
local fish = require(script.Parent.Types)

--// Constants & Variables
local services: {[string]: fish.Service<unknown>} = {}
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

	@param service string | ModuleScript -- The name or script instance of the service
	@param definition fish.ServiceDef<T>? -- The definition of the service
	@return fish.Service<T> -- The service itself
]=]
function Server.service<T>(service: string | ModuleScript, definition: (fish.ServiceDef<T> | unknown)?): fish.Service<T>
	local name, scriptInstance
	if typeof(service) == "Instance" and service:IsA("ModuleScript") then
		name = service.Name
		scriptInstance = service
	else
		name = service
	end
	
	if definition == nil or services[name] ~= nil then
		-- Get service
		return services[name] :: fish.Service<T>
	else
		-- Construct service
		assert(type(name) == "string", `Name must be a string; got {typeof(name)}`)
		assert(#name > 0, "Name must be a non-empty string")
		assert(type(definition) == "table", `Definition must be a table; got {typeof(definition)}`)
		assert(scriptInstance, `Script instance must be provided; got type {typeof(scriptInstance)}`)
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

		local service = definition :: fish.ServiceDef<T>

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

		services[name] = service
		return services[name] :: fish.Service<T>
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
function Server.signal(unreliable: boolean?): Types.RemoteSignal
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
function Server.property(initialValue: any): Types.RemoteProperty
	return { PROPERTY_MARKER, initialValue } :: any
end

--[=[
	Starts all created services.
	Services cannot be created after called.

	@param disableConfirmAndMutexSafety boolean? -- Whether self.confirm() should be disabled, and whether mutex won't automatically unlock if an error occurs before self.Mutex:Unlock() is called
	@return Promise.TypedPromise<> -- Promise that resolves when started
]=]
function Server.start(disableConfirmAndMutexSafety: boolean?): Promise.TypedPromise<>
	if started then
		return Promise.reject("fish is already started")
	elseif isStarting then
		return Promise.reject("fish is already starting")
	else
		isStarting = true

		-- Sort service load order by priority
		local hasPriority: {fish.Service<unknown>} = {}
		local noPriority: {fish.Service<unknown>} = {}
		for name, service in services do
			service.__fishMetadata.Name = name
			if service.LoadPriority then
				table.insert(hasPriority, service)
			else
				table.insert(noPriority, service)
			end
		end
		table.sort(hasPriority, function(a: fish.Service<unknown>, b: fish.Service<unknown>)
			return (a.LoadPriority :: number) > (b.LoadPriority :: number)
		end)
		
		local sortedServices: {fish.Service<unknown>} = {}
		for _, service in ipairs(hasPriority) do
			table.insert(sortedServices, service)
		end
		for _, service in noPriority do
			table.insert(sortedServices, service)
		end

		return Promise.new(function(resolve)
			local servicesFolder = Instance.new("Folder")
			servicesFolder.Name = "Services"
			servicesFolder.Parent = script.Parent

			-- Wrap function to alter parameter functionality with player
			local function wrapFunction<K, V>(func: (...any) -> ())
				local mutex: { Locked: boolean, Queue: {thread}, PlayerQueue: { [Player]: { Locked: boolean, Queue: {thread} } } } = {
					Locked = false,
					Queue = {},
					PlayerQueue = {}
				}
				return function(self: {[K]: V}, player: Player, ...)
					-- Create a local copy of "self" and inject "player" into it
					local localSelf = {}
					for k, v in self do
						localSelf[k] = v
					end
					localSelf.Player = player

					-- Implement mutex and inject it
					local threadLockState: { Global: boolean, Player: { [Player]: true } } = {
						Global = false,
						Player = {}
					}
					localSelf.Mutex = {
						Lock = function(self: any, player: Player?)
							if player then
								assert(not threadLockState.Player[player], "Cannot lock an already locked mutex in the same thread")
								threadLockState.Player[player] = true

								local playerMutex = mutex.PlayerQueue[player]
								if playerMutex == nil then
									playerMutex = {
										Locked = false,
										Queue = {}
									}
									mutex.PlayerQueue[player] = playerMutex
								end

								if playerMutex.Locked then
									table.insert(playerMutex.Queue, coroutine.running())
									coroutine.yield()
								else
									playerMutex.Locked = true
								end
							else
								assert(not threadLockState.Global, "Cannot lock an already locked mutex in the same thread")
								threadLockState.Global = true

								if mutex.Locked then
									table.insert(mutex.Queue, coroutine.running())
									coroutine.yield()
								else
									mutex.Locked = true
								end
							end
						end,
						Unlock = function(self: any, player: Player?)
							if player then
								assert(threadLockState.Player[player], "Cannot unlock an already unlocked mutex")
								threadLockState.Player[player] = nil

								local playerMutex = mutex.PlayerQueue[player]
								assert(playerMutex and playerMutex.Locked, "Cannot unlock an already unlocked mutex")

								if #playerMutex.Queue > 0 then
									local nextThread = table.remove(playerMutex.Queue, 1)
									if nextThread then
										coroutine.resume(nextThread)
									end
								else
									playerMutex.Locked = false
									mutex.PlayerQueue[player] = nil
								end
							else
								assert(threadLockState.Global, "Cannot unlock an already unlocked mutex in the same thread")
								assert(mutex.Locked, "Cannot unlock an already unlocked mutex")
								threadLockState.Global = false
								if #mutex.Queue > 0 then
									local nextThread = table.remove(mutex.Queue, 1)
									if nextThread then
										coroutine.resume(nextThread)
									end
								else
									mutex.Locked = false
								end
							end
						end,
						Wrap = function<A..., R...>(self: any, func: (A...) -> (R...), ...: A...): (boolean, R...)
							assert(not threadLockState.Global, "Cannot wrap mutex as this thread is already locked")
							localSelf.Mutex:Lock()
							local results: {any} = {pcall(func, ...)}
							localSelf.Mutex:Unlock()
							return unpack(results)
						end,
						WrapPlayer = function<A..., R...>(self: any, player: Player, func: (A...) -> (R...), ...: A...): (boolean, R...)
							assert(not threadLockState.Player[player], "Cannot wrap mutex as this thread is already locked")
							localSelf.Mutex:Lock(player)
							local results: {any} = {pcall(func, ...)}
							localSelf.Mutex:Unlock(player)
							return unpack(results)
						end
					}
					
					-- Disable confirm and mutex safety if asked
					if disableConfirmAndMutexSafety then
						localSelf.confirm = function()
							error("self.confirm() has been disabled. See fish.start()'s arguments to change this behavior.")
						end

						local returnValues = {func(localSelf, ...)}

						if mutex.Locked and threadLockState.Global then
							localSelf.Mutex:Unlock()
						end

						for player, isLocked in threadLockState.Player do
							local playerMutex = mutex.PlayerQueue[player]
    						if isLocked and playerMutex and playerMutex.Locked then
								localSelf.Mutex:Unlock(player)
							end
						end

						return unpack(returnValues)
					end

					-- Implement confirm and inject it
					local returnValues: {any} = {"__fish_caught_error", "__fish_unknown_error"}
					localSelf.confirm = function<T>(value: T?): T
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
					if coroutine.status(thread) ~= "dead" then
						repeat task.wait() until coroutine.status(thread) == "dead"
					end

					if mutex.Locked and threadLockState.Global then
						localSelf.Mutex:Unlock()
					end

					for player, isLocked in threadLockState.Player do
						local playerMutex = mutex.PlayerQueue[player]
						if isLocked and playerMutex and playerMutex.Locked then
							localSelf.Mutex:Unlock(player)
						end
					end
					
					return unpack(returnValues)
				end
			end

			for _, service in ipairs(sortedServices) do
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

					local comm = ServerComm.new(servicesFolder, service.__fishMetadata.Name) :: any
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
					
					-- Expose parent to client
					local serviceFolder = assert(servicesFolder:FindFirstChild(service.__fishMetadata.Name) :: Folder?)
					local serviceScriptInstance: ModuleScript = service.__fishMetadata.Instance
					local fullNameSegments = serviceScriptInstance:GetFullName():split(".")
					fullNameSegments[#fullNameSegments] = nil
					serviceFolder:SetAttribute("Parent", table.concat(fullNameSegments, "."))

					service.__fishMetadata = nil
					service:Start()
				end)
			end
			
			started = true
			startedSignal:Fire()
			isStarting = false
			script.Parent.Client:SetAttribute("ServerStarted", true)
			resolve()
		end)
	end
end

--[=[
	Returns a promise that is resolved once services are started.

	@return Promise.TypedPromise<> -- Promise that resolves when started
]=]
function Server.onStart(): Promise.TypedPromise<>
	if started then
		return Promise.resolve()
	else
		return Promise.fromEvent(startedSignal) :: Promise.TypedPromise<>
	end
end

return Server