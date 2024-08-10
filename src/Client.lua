local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Client = {}

--// Dependencies
local ClientComm = require(ReplicatedStorage.Packages.Comm).ClientComm
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local fish = require(script.Parent.Types)

--// Constants & Variables
local controllers: {[string]: fish.Controller<any>} = {}
local services: {[string]: fish.ServiceRef} = {}
local started = false
local isStarting = false
local startedSignal = Signal.new()

--[=[
	Builds a service using the service's definition folder.
]=]
local function buildService(serviceDefinition: Folder): fish.ServiceRef
	local comm = ClientComm.new(serviceDefinition.Parent :: Folder, true, serviceDefinition.Name) :: any
	local service = comm:BuildObject()

	services[serviceDefinition.Name] = service
	return service
end

--[=[
	Reference to the ClientService module which represents a service from the client context
]=]
Client.ClientService = script.Parent.ClientService :: ModuleScript

--[=[
	Constructs/gets a controller.
	If the controller already exists, the existing controller will be returned.
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
]=]
function Client.service(name: string): fish.ServiceRef?
	-- assert(game:GetAttribute("fishServerStarted") == true, "fish server has not started")
	
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
]=]
function Client.getServices(): {[string]: fish.ServiceRef}
	-- assert(game:GetAttribute("fishServerStarted") == true, "fish server has not started")
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
]=]
function Client.getServiceNames(): {string}
	-- assert(game:GetAttribute("fishServerStarted") == true, "fish server has not started")
	local servicesFolder: Folder = script.Parent.Services
	return TableUtil.Map(servicesFolder:GetChildren(), function(serviceFolder)
		return serviceFolder.Name
	end)
end

--[=[
	Starts all created controllers.
	Controllers cannot be created after called.
]=]
function Client.start(): Promise.TypedPromise<any>
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
]=]
function Client.onStart(): Promise.TypedPromise<any>
	if started then
		return Promise.resolve()
	else
		return Promise.fromEvent(startedSignal)
	end
end

-- Wait for server to initialize
if RunService:IsClient() then
	if game:GetAttribute("fishServerStarted") ~= true then
		if ReplicatedFirst:FindFirstChild("fishServerStarted") == nil then
			local signal = Signal.new()
			local connection = ReplicatedFirst.ChildAdded:Connect(function(object)
				if object.Name == "fishServerStarted" then
					signal:Fire()
				end
			end)
			signal:Wait()
			signal:Destroy()
			connection:Disconnect()
		end
		game:SetAttribute("fishServerStarted", true)
		ReplicatedFirst:FindFirstChild("fishServerStarted"):Destroy()
	end
	
	-- Add ClientService modules
	for _, name in Client.getServiceNames() do
		local serviceModule = Client.ClientService:Clone()
		serviceModule.Name = name
		serviceModule.Parent = ServerStorage.Server.Services
	end
end

return Client