--[=[
	@class Client

	Contains the client functionality of fish framework
]=]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Client = {}

--// Dependencies
local ClientComm = require(script.Parent.Parent.Comm).ClientComm
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local fish = require(script.Parent.Types)

--// Constants & Variables
local controllers: {[string]: fish.Controller<unknown>} = {}
local services: {[string]: fish.ServiceRef} = {}
local started = false
local isStarting = false
local startedSignal = Signal.new()
local generatedObfuscationString: string?

--[=[
	@ignore
	@within Client
	Generates a string used to obfuscate names.
]=]
local function generateObfuscationString(): string
	if generatedObfuscationString == nil then
		generatedObfuscationString = HttpService:GenerateGUID(false)
	end
	return generatedObfuscationString :: string
end

--[=[
	@ignore
	@within Client
	Builds a service using the service's definition folder.
]=]
local function buildService(serviceDefinition: Folder): fish.ServiceRef
	local comm = ClientComm.new(serviceDefinition.Parent :: Folder, true, serviceDefinition.Name) :: any
	local service = comm:BuildObject({function(args)
		if args[1] == "__fish_caught_error" then
			if args[2] == "__fish_unknown_error" then
				if RunService:IsStudio() then
					error("An error has occurred on the server! (fish framework does not send error messages to the client while running in Studio with obfuscation enabled)\n", 0)
				else
					error("Unknown error\n", 0)
				end
			else
				error(args[2], 0)
			end
		end
		return true
		-- (Args) -> (boolean, ...any)
	end})

	services[serviceDefinition.Name] = service
	return service
end

--[=[
	Constructs/gets a controller.
	If the controller already exists, the existing controller will be returned.

	@param controller string | ModuleScript -- The name or script instance of the controller
	@param definition fish.ControllerDef<T>? -- The definition of the controller
	@return fish.Controller<T> -- The controller itself
]=]
function Client.controller<T>(controller: string | ModuleScript, definition: (fish.ControllerDef<T> | unknown)?): fish.Controller<T>
	local name, scriptInstance
	if typeof(controller) == "Instance" and controller:IsA("ModuleScript") then
		name = controller.Name
		scriptInstance = controller
	else
		name = controller
	end

	if definition == nil or controllers[name] ~= nil then
		-- Get controller
		return controllers[name] :: fish.Controller<T>
	else
		-- Construct controller
		assert(type(name) == "string", `Name must be a string; got {typeof(name)}`)
		assert(#name > 0, "Name must be a non-empty string")
		assert(type(definition) == "table", `Controller must be a table; got {typeof(definition)}`)
		assert(scriptInstance, `Script instance must be provided; got type {typeof(scriptInstance)}`)
		assert(controllers[name] == nil, `Controller "{name}" already exists`)

		if scriptInstance.Parent then
			local loadRequirementModule = scriptInstance.Parent:FindFirstChild("@load")
			if loadRequirementModule ~= nil and loadRequirementModule:IsA("ModuleScript") then
				local shouldLoad = (require)(loadRequirementModule)(scriptInstance)
				if not shouldLoad then
					warn(`Controller "{name}" was loaded even though @load indicates not to. Look for any other scripts that are unexpectedly requiring its module.`)
				end
			end
		end

		assert(not started, "Controller cannot be added after calling \"fish.Start()\"")

		local controller = definition :: fish.ControllerDef<T>

		if type(controller.Client) ~= "table" then
			controller.Client = {}
		end

		if type(controller.Start) ~= "function" then
			controller.Start = function()
				return nil
			end
		end

		controller.__fishMetadata = {
			Instance = scriptInstance
		}

		controllers[name] = controller
		return controllers[name] :: fish.Controller<T>
	end
end

--[=[
	Constructs all controllers out of the modules in the children in the given instance.
	If the parent of a controller module has an "@load" module, it will use it to check whether it should load any controller modules in that folder.

	@param folder Instance -- The instance containing the controller modules
]=]
function Client.controllerDeep(folder: Instance)
	assert(typeof(folder) == "Instance", `Folder must be an Instance; got {typeof(folder)}`)
	
	local requirePromises: {Promise.Promise} = {}
	for _, object in folder:GetDescendants() do
		if object:IsA("ModuleScript") then
			if object.Parent ~= nil and object.Name ~= "@load" then
				local loadRequirementModule = object.Parent:FindFirstChild("@load")
				if loadRequirementModule ~= nil and loadRequirementModule:IsA("ModuleScript") then
					local shouldLoad = (require)(loadRequirementModule)(object)
					if not shouldLoad then
						continue
					end
				end
			end
			table.insert(requirePromises, Promise.try(require, object):timeout(5, "CONTROLLER_REQUIRE_TIMEOUT"):catch(function(err)
				if err == "CONTROLLER_REQUIRE_TIMEOUT" then
					warn(`Controller "{object.Name}" took too long to be required, look for an unresolvable dependency.`)
				else
					warn(err)
				end
			end))
		end
	end
	Promise.all(requirePromises):await()
end

--[=[
	Get a service.

	@param name string -- The name of the service
	@return fish.ServiceRef? -- The reference to the service
]=]
function Client.service(name: string): fish.ServiceRef?
	local servicesFolder = assert(script.Parent:FindFirstChild("Services") :: Folder?)
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
	local servicesFolder = assert(script.Parent:FindFirstChild("Services") :: Folder?)
	for _, service in servicesFolder:GetChildren() do
		if services[service.Name] == nil then
			buildService(service :: Folder)
		end
	end
	return services
end

--[=[
	Starts all created controllers.
	Controllers cannot be created after called.

	@param obfuscate boolean? -- Whether to obfuscate controller and service names
	@return Promise.TypedPromise<> -- Promise that resolves when started
]=]
function Client.start(obfuscate: boolean?): Promise.TypedPromise<>
	if started then
		return Promise.reject("fish already started")
	elseif isStarting then
		return Promise.reject("fish is already starting")
	else
		isStarting = true

		-- Sort controller load order by priority
		local hasPriority: {fish.Controller<unknown>} = {}
		local noPriority: {fish.Controller<unknown>} = {}
		for _, controller in controllers do
			if controller.LoadPriority then
				table.insert(hasPriority, controller)
			else
				table.insert(noPriority, controller)
			end
		end
		table.sort(hasPriority, function(a: fish.Controller<unknown>, b: fish.Controller<unknown>)
			return (a.LoadPriority :: number) > (b.LoadPriority :: number)
		end)
		
		local sortedControllers: {fish.Controller<unknown>} = {}
		for _, controller in ipairs(hasPriority) do
			table.insert(sortedControllers, controller)
		end
		for _, controller in noPriority do
			table.insert(sortedControllers, controller)
		end

		-- Obfuscate
		if obfuscate and not RunService:IsStudio() then
			local servicesFolder = script.Parent:FindFirstChild("Services") :: Folder?
			local instancesToDestroy: {Instance?} = {servicesFolder}
			if servicesFolder then
				for _, instance in servicesFolder:GetDescendants() do
					if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
						instance.Name = generateObfuscationString()
						instance.Parent = game
					elseif instance:IsA("Folder") then
						instance:SetAttribute("Parent", nil)
						table.insert(instancesToDestroy, instance)
					else
						table.insert(instancesToDestroy, instance)
					end
				end
			end
			for _, instance in instancesToDestroy do
				if instance then
					instance:Destroy()
				end
			end
			ServerStorage:ClearAllChildren()
			table.clear(services)
			table.freeze(services)
			
			for _, controller in controllers do
				controller.__fishMetadata.Instance.Name = generateObfuscationString()
				controller.__fishMetadata.Instance.Parent = game
				controller.__fishMetadata = nil
			end
			local client = StarterPlayer:WaitForChild("StarterPlayerScripts"):FindFirstChild("Client")
			if client ~= nil then
				client:Destroy()
			end
			table.clear(controllers)
			table.freeze(controllers)
		end

		return Promise.new(function(resolve)
			for _, controller in ipairs(sortedControllers) do
				Promise.try(function()
					controller:Start()
				end)
			end

			started = true
			startedSignal:Fire()
			isStarting = false
			resolve()
		end)
	end
end

--[=[
	Returns a promise that is resolved once controllers are started.

	@return Promise.TypedPromise<> -- Promise that resolves when started
]=]
function Client.onStart(): Promise.TypedPromise<>
	if started then
		return Promise.resolve()
	else
		return Promise.fromEvent(startedSignal) :: Promise.TypedPromise<>
	end
end

-- Wait for server to initialize
if RunService:IsClient() then
	if script:GetAttribute("ServerStarted") ~= true then
		script:GetAttributeChangedSignal("ServerStarted"):Wait()
	end
	
	-- Add ClientService modules
	local ClientService = script.Parent.ClientService
	local servicesFolder = assert(script.Parent:FindFirstChild("Services") :: Folder?)
	local serviceFolders = servicesFolder:GetChildren() :: {Folder}
	for _, serviceFolder in serviceFolders do
		local currentLocation: Instance = game
		local parent = serviceFolder:GetAttribute("Parent") :: string?
		if parent == nil then
			serviceFolder:GetAttributeChangedSignal("Parent"):Wait()
			parent = serviceFolder:GetAttribute("Parent") :: string?
		end
		for _, childName in assert(parent):split(".") do
			local existingLocation = currentLocation:FindFirstChild(childName)
			if existingLocation ~= nil then
				currentLocation = existingLocation
			else
				local folder = Instance.new("Folder")
				folder.Name = childName
				folder.Parent = currentLocation
				currentLocation = folder
			end
		end

		-- Overwrite
		local existingInstance = currentLocation:FindFirstChild(serviceFolder.Name)
		if existingInstance ~= nil then
			if existingInstance:IsA("ModuleScript") then
				warn(`Service "{serviceFolder.Name}" is exposed to the client and its source code could be read! Consider moving the module to a secure location such as ServerStorage.`)
			else
				warn(`Service "{serviceFolder.Name}" overwrote an existing instance of class "{existingInstance.ClassName}" at {parent}.{serviceFolder.Name}! Ensure there is no instance at that location before fish is started.`)
			end
			existingInstance:Destroy()
		end
		
		local serviceModule = ClientService:Clone()
		serviceModule.Name = serviceFolder.Name
		serviceModule.Parent = currentLocation
	end
end

return Client