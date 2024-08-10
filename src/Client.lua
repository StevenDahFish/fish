--[=[
	@class Client

	Contains the client functionality of fish framework
]=]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Client = {}

--// Dependencies
local ClientComm = require(script.Parent.Parent.Comm).ClientComm
local TableUtil = require(script.Parent.Parent.TableUtil)
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local fish = require(script.Parent.Types)

--// Constants & Variables
local controllers: {[string]: fish.Controller<any>} = {}
local services: {[string]: fish.ServiceRef} = {}
local started = false
local isStarting = false
local startedSignal = Signal.new()

--[=[
	@ignore
	@within Client
	Builds a service using the service's definition folder.
]=]
local function buildService(serviceDefinition: Folder): fish.ServiceRef
	local comm = ClientComm.new(serviceDefinition.Parent :: Folder, true, serviceDefinition.Name) :: any
	local service = comm:BuildObject()

	services[serviceDefinition.Name] = service
	return service
end

--[=[
	@prop ClientService ModuleScript
	@within Client
	Reference to the ClientService module which represents a service from the client context
]=]
Client.ClientService = script.Parent.ClientService :: ModuleScript

--[=[
	Constructs/gets a controller.
	If the controller already exists, the existing controller will be returned.

	@param name string -- The name of the controller
	@param controllerDef fish.ControllerDef<T>? -- The definition of the controller
	@return fish.Controller<T> -- The controller itself
]=]
function Client.controller<T>(name: string, controllerDef: fish.ControllerDef<T>?): fish.Controller<T>
	if controllerDef == nil or controllers[name] ~= nil then
		-- Get controller
		return controllers[name] :: fish.Controller<T>
	else
		-- Construct controller
		assert(type(name) == "string", `Name must be a string; got {typeof(controllerDef.Name)}`)
		assert(#name > 0, "Name must be a non-empty string")
		assert(type(controllerDef) == "table", `Controller must be a table; got {typeof(controllerDef)}`)
		assert(controllers[name] == nil, `Controller "{controllerDef.Name}" already exists`)
		assert(not started, "Controller cannot be added after calling \"fish.Start()\"")

		local controller = controllerDef

		if type(controller.Client) ~= "table" then
			controller.Client = {}
		end
		if type(controller.Start) ~= "function" then
			controller.Start = function() end
		end

		controllers[name] = controller :: fish.Controller<T>
		return controllers[name]
	end
end

--[=[
	Constructs all controllers out of the modules in the children in the given instance.

	@param folder Instance -- The instance containing the controller modules
]=]
function Client.controllerDeep(folder: Instance)
	assert(typeof(folder) == "Instance", `Folder must be an Instance; got {typeof(folder)}`)
	for _, object in folder:GetDescendants() do
		if object:IsA("ModuleScript") then
			-- Why luau
			(require)(object)
		end
	end
end

--[=[
	Get a service.

	@param name string -- The name of the service
	@return fish.ServiceRef? -- The reference to the service
]=]
function Client.service(name: string): fish.ServiceRef?
	-- assert(game:GetAttribute("__fishServerStarted") == true, "fish server has not started")
	
	local servicesFolder: Folder = script.Parent.Services
	local serviceFolder = servicesFolder:FindFirstChild(name) :: Folder?
	assert(serviceFolder ~= nil, `Service "{name}" does not exist`)
	
	if services[name] == nil then
		return buildService(serviceFolder)
	else
		return services[name]
	end
end

--[=[
	Get all public services visible to the client.
	
	@return {[string]: fish.ServiceRef} -- The list of services indexed by its name
]=]
function Client.getServices(): {[string]: fish.ServiceRef}
	-- assert(game:GetAttribute("__fishServerStarted") == true, "fish server has not started")
	local servicesFolder: Folder = script.Parent.Services
	for _, service in servicesFolder:GetChildren() do
		if services[service.Name] == nil then
			buildService(service :: Folder)
		end
	end
	return services
end

--[=[
	Get all public service names visible to the client.

	@return {string} -- The list of service names
]=]
function Client.getServiceNames(): {string}
	-- assert(game:GetAttribute("__fishServerStarted") == true, "fish server has not started")
	local servicesFolder: Folder = script.Parent.Services
	return TableUtil.Map(servicesFolder:GetChildren(), function(serviceFolder)
		return serviceFolder.Name
	end)
end

--[=[
	Starts all created controllers.
	Controllers cannot be created after called.

	@return Promise.TypedPromise<nil> -- Promise that resolves when started
]=]
function Client.start(): Promise.TypedPromise<nil>
	-- If starting
	if started then
		return Promise.reject("fish already started")
	elseif isStarting then
		return Promise.reject("fish is already starting")
	else
		return Promise.new(function(resolve)
			for _, controller in controllers do
				Promise.try(function()
					controller:Start()
				end)
			end
			started = true
			startedSignal:Fire()
			resolve()
		end)
	end
end

--[=[
	Returns a promise that is resolved once controllers are started.

	@return Promise.TypedPromise<nil> -- Promise that resolves when started
]=]
function Client.onStart(): Promise.TypedPromise<nil>
	if started then
		return Promise.resolve()
	else
		return Promise.fromEvent(startedSignal)
	end
end

-- Wait for server to initialize
if RunService:IsClient() then
	if game:GetAttribute("__fishServerStarted") ~= true then
		if script.Parent:FindFirstChild("__fishServerStarted") == nil then
			local signal = Signal.new()
			local connection = script.Parent.ChildAdded:Connect(function(object)
				if object.Name == "__fishServerStarted" then
					signal:Fire()
				end
			end)
			signal:Wait()
			signal:Destroy()
			connection:Disconnect()
		end
		game:SetAttribute("__fishServerStarted", true)
		script.Parent:FindFirstChild("__fishServerStarted"):Destroy()
	end
	
	-- Add ClientService modules
	for _, name in Client.getServiceNames() do
		local serviceModule = Client.ClientService:Clone()
		serviceModule.Name = name
		serviceModule.Parent = ServerStorage.Server.Services
	end
end

return Client