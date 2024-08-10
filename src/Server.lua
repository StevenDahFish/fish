--!nonstrict
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Server = {}

--// Dependencies
local DependencyTypes = require(script.Parent.DependencyTypes)
local ServerComm = require(script.Parent.Parent.Comm).ServerComm
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local fish = require(script.Parent.Types)

--// Constants & Variables
local services: {[string]: fish.Service<any>} = {}
local started = false
local isStarting = false
local startedSignal = Signal.new()

--[=[
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
]=]
function Server.service<T>(name: string, serviceDef: fish.ServiceDef<T>?): fish.Service<T>
	if serviceDef == nil or services[name] ~= nil then
		-- Get service
		return services[name] :: fish.Service<T>
	else
		-- Construct service
		assert(type(name) == "string", `Name must be a string; got {typeof(serviceDef.Name)}`)
		assert(#name > 0, "Name must be a non-empty string")
		assert(type(serviceDef) == "table", `Service must be a table; got {typeof(serviceDef)}`)
		assert(services[name] == nil, `Service "{serviceDef.Name}" already exists`)
		assert(not started, "Service cannot be added after calling \"fish.Start()\"")

		local service = serviceDef

		if type(service.Client) ~= "table" then
			service.Client = {}
		end
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
		if type(service.Start) ~= "function" then
			service.Start = function() end
		end

		services[name] = service :: fish.Service<T>
		return services[name]
	end
end

--[=[
	Constructs all services out of the modules in the descendants in the given instance.
]=]
function Server.serviceDeep(folder: Instance)
	assert(typeof(folder) == "Instance", `Folder must be an Instance; got {typeof(folder)}`)
	for _, object in folder:GetDescendants() do
		if object:IsA("ModuleScript") then
			-- Why luau
			(require)(object)
		end
	end
end

--[=[
	Returns a marker that will transform into a RemoteSignal once all services are started.
]=]
function Server.signal(): DependencyTypes.RemoteSignal
	return SIGNAL_MARKER
end

--[=[
	Returns a marker that will transform into a RemoteProperty once all services are started.
]=]
function Server.property(initialValue: any): DependencyTypes.RemoteProperty
	return { PROPERTY_MARKER, initialValue } :: DependencyTypes.RemoteProperty
end

--[=[
	Starts all created services.
	Services cannot be created after called.
]=]
function Server.start(): Promise.TypedPromise<any>
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
			local function wrapFunction(func)
				return function(self, player, ...)
					-- Create a local copy of `self` and inject `player` into it
					local localSelf = {}
					for k, v in self do
						localSelf[k] = v
					end
					localSelf.Player = player
					
					-- Call the original function with the modified `localSelf`
					return func(localSelf, ...)
				end
			end

			for name, service in services do
				Promise.try(function()
					local comm = ServerComm.new(servicesFolder, name) :: any
					local client = service.Client :: {[any]: any}
					for k, v in client do
						if type(v) == "function" then
							client[k] = wrapFunction(v)
							comm:WrapMethod(service.Client, k)
						elseif v == SIGNAL_MARKER then
							client[k] = comm:CreateSignal(k, false)
						elseif v == UNRELIABLE_SIGNAL_MARKER then
							client[k] = comm:CreateSignal(k, true)
						elseif type(v) == "table" and v[1] == PROPERTY_MARKER then
							client[k] = comm:CreateProperty(k, v[2])
						end
					end
					service.Client = client
					
					service:Start()
				end)
			end
			
			isStarting = false
			started = true
			startedSignal:Fire()
			local startedValue = Instance.new("BinaryStringValue")
			startedValue.Name = "fishServerStarted"
			startedValue.Parent = ReplicatedFirst
			resolve()
		end)
	end
end

--[=[
	Returns a promise that is resolved once services are started.
]=]
function Server.onStart(): Promise.TypedPromise<any>
	if started then
		return Promise.resolve()
	else
		return Promise.fromEvent(startedSignal)
	end
end

--[=[
	Type used to describe the "self" object in Client functions
	```lua
	function MyService.Client.PrintPlayer(self: fish.self<client, server>)
		print(self.Player)
	end
	```
]=]
export type self<C, S> = C & {
	Player: Player,
	Server: S,
	[any]: any
};

return Server