--[=[
	@class Server

	Contains the server functionality of fish framework
]=]

const RunService = game:GetService("RunService")
const Players = game:GetService("Players")
const Server = {}

--// Dependencies
const ServerComm = require(script.Parent.Parent.Comm).ServerComm
const Promise = require(script.Parent.Parent.Promise)
const Signal = require(script.Parent.Parent.Signal)
const Types = require(script.Parent.Types)
const fish = require(script.Parent.Types)

--[=[
	@ignore
	@type PromiseEvent<T...> { Connect: (self: any, callback: (T...) -> ...any) -> { Disconnect: (self: any) -> ...any, [any]: any } }
	@within Server
	The event shape `Promise.fromEvent` accepts.
	`Signal.Connection` and the connection type `Promise.fromEvent` expects are identical
	apart from the latter's `[any]: any` indexer, which makes the two mutually
	incompatible, so the signal is described with this type at the call site.
]=]
type PromiseEvent<T...> = {
	Connect: (self: any, callback: (T...) -> ...any) -> { Disconnect: (self: any) -> ...any, [any]: any }
}

--// Constants & Variables
local services: {[string]: fish.RegisteredService} = {}
local serviceDirectories: {Instance} = {}
local started = false
local isStarting = false
local startedSignal: Signal.Signal<> = Signal.new()

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
	@ignore
	@prop N/A nil
	@within Server
	Thresholds the mutex uses to warn about lock contention
]=]
local MUTEX_WARN_GLOBAL_DEPTH_THRESHOLD = 4
local MUTEX_WARN_PLAYER_DEPTH_THRESHOLD = 4
local MUTEX_WARN_GLOBAL_QUEUE_BASE_THRESHOLD = 10 -- Scales based on player count
local MUTEX_WARN_PLAYER_QUEUE_THRESHOLD = 10
local MUTEX_WARN_RATE_LIMIT_SECONDS = 5
local MUTEX_HELD_TIME_POLL_SECONDS = 0.25

--[=[
	@ignore
	@type MutexEntry { Locked: boolean, Owner: thread?, Depth: number, Queue: {thread}, HoldStartedAt: number?, HoldExpectedMaxSeconds: number?, HoldWarned: boolean?, OriginTraceback: string? }
	@within Server
	One lock held by a mutex; a mutex has one global entry and one entry per player
]=]
type MutexEntry = {
	Locked: boolean,
	Owner: thread?,
	Depth: number,
	Queue: {thread},

	HoldStartedAt: number?,
	HoldExpectedMaxSeconds: number?,
	HoldWarned: boolean?,
	OriginTraceback: string?
}

--[=[
	@ignore
	@type MutexWarnType "Depth" | "Queue" | "Held"
	@within Server
	The kinds of contention a mutex warns about
]=]
type MutexWarnType = "Depth" | "Queue" | "Held"

--[=[
	@ignore
	@type MutexWarnTimes {[MutexWarnType]: number}
	@within Server
	When each kind of mutex warning was last emitted, used to rate limit them
]=]
type MutexWarnTimes = {[MutexWarnType]: number}

--[=[
	@ignore
	@within Server
	Stops the current thread when the given value is falsy.
	Passed to the functions given to `Mutex:Wrap()` and `Mutex:WrapPlayer()`, which run on
	their own thread and therefore cannot use the `self.confirm()` of the client function
	that started them.
]=]
local function silentAssert<T>(value: T?): T
	if not value then
		if coroutine.isyieldable() then
			task.defer(coroutine.close, coroutine.running())
			coroutine.yield()
		else
			error("Unable to silently fail, current thread is not yieldable")
		end
	end
	return value
end

--[=[
	@ignore
	@within Server
	Creates the mutex for a single client function.
	Returns the mutex that gets injected into `self`, along with a function that releases every
	lock still owned by a given thread; the wrapper uses it to clean up after the client
	function returns or errors.
]=]
local function createMutex(label: string): (Types.Mutex, (owner: thread) -> ())
	local global: MutexEntry = {
		Locked = false,
		Owner = nil,
		Depth = 0,
		Queue = {}
	}
	local playerEntries: {[Player]: MutexEntry} = {}

	local lastWarnAtGlobal: MutexWarnTimes = {}
	local lastWarnAtPlayer: {[Player]: MutexWarnTimes} = {}

	local function getTracebackFirstLine(): string
		local success, traceback = pcall(debug.traceback, nil, 2)

		if not success or type(traceback) ~= "string" then
			return "Unknown"
		end

		return traceback:split("\n")[2] or "Unknown"
	end

	local function describe(player: Player?): string
		if player then
			return `"{label}" of player (#{player.UserId})`
		end
		return `"{label}"`
	end

	local function warnTimesFor(player: Player?): MutexWarnTimes
		if player == nil then
			return lastWarnAtGlobal
		end

		local existing = lastWarnAtPlayer[player]
		if existing ~= nil then
			return existing
		end

		local warnTimes: MutexWarnTimes = {}
		lastWarnAtPlayer[player] = warnTimes
		return warnTimes
	end

	local function entryFor(player: Player?): MutexEntry
		if player == nil then
			return global
		end

		local existing = playerEntries[player]
		if existing ~= nil then
			return existing
		end

		local entry: MutexEntry = {
			Locked = false,
			Owner = nil,
			Depth = 0,
			Queue = {}
		}
		playerEntries[player] = entry
		return entry
	end

	local function warnRateLimited(player: Player?, warnType: MutexWarnType, message: string)
		local warnTimes = warnTimesFor(player)

		local now = os.clock()
		local last = warnTimes[warnType]
		if last ~= nil and now - last < MUTEX_WARN_RATE_LIMIT_SECONDS then
			return
		end

		warnTimes[warnType] = now
		warn(message)
	end

	local function warnIfDepthLarge(player: Player?, entry: MutexEntry)
		local threshold = if player then MUTEX_WARN_PLAYER_DEPTH_THRESHOLD else MUTEX_WARN_GLOBAL_DEPTH_THRESHOLD

		if entry.Depth <= threshold then
			return
		end

		warnRateLimited(
			player,
			"Depth",
			`High depth ({entry.Depth}) for {describe(player)}. Check if you are using Unlock or if there is recursion{if entry.OriginTraceback ~= nil then `: {entry.OriginTraceback}` else "."}`
		)
	end

	local function warnIfQueueLarge(player: Player?, entry: MutexEntry)
		local queueSize = #entry.Queue
		local threshold = if player
			then MUTEX_WARN_PLAYER_QUEUE_THRESHOLD
			else MUTEX_WARN_GLOBAL_QUEUE_BASE_THRESHOLD * math.max(#Players:GetPlayers(), 1)
		if queueSize <= threshold then
			return
		end

		warnRateLimited(player, "Queue", `Large queue ({queueSize}/{threshold}) for {describe(player)}. Usage is high or a lock is being held for too long{if entry.OriginTraceback ~= nil then `: {entry.OriginTraceback}` else "."}`)
	end

	local function startHoldTimer(entry: MutexEntry, player: Player?, expectedMaxSeconds: number?)
		if expectedMaxSeconds == nil then
			return
		end

		entry.HoldStartedAt = os.clock()
		entry.HoldExpectedMaxSeconds = expectedMaxSeconds
		entry.HoldWarned = false

		task.spawn(function()
			while entry.Locked do
				local startedAt = entry.HoldStartedAt
				local expectedMax = entry.HoldExpectedMaxSeconds
				if startedAt == nil or expectedMax == nil then
					return
				end

				if entry.HoldWarned == false then
					local elapsed = os.clock() - startedAt
					if elapsed > expectedMax then
						entry.HoldWarned = true
						warnRateLimited(player, "Held", (`Lock held longer than expected (%.2fs) for {describe(player)}{if entry.OriginTraceback ~= nil then `: {entry.OriginTraceback}` else "."}`):format(expectedMax))
						return
					end
				end
				task.wait(MUTEX_HELD_TIME_POLL_SECONDS)
			end
		end)
	end

	local function clearHoldTimer(entry: MutexEntry)
		entry.HoldStartedAt = nil
		entry.HoldExpectedMaxSeconds = nil
		entry.HoldWarned = nil
	end

	local function lock(expectedMaxRuntimeSeconds: number?, player: Player?, traceback: string)
		local currentThread = coroutine.running()
		local entry = entryFor(player)

		-- Already locked and attempting to re-enter in the same thread
		if entry.Locked and entry.Owner == currentThread then
			entry.Depth += 1
			warnIfDepthLarge(player, entry)
			return
		end

		if entry.Locked then
			table.insert(entry.Queue, currentThread)
			warnIfQueueLarge(player, entry)
			coroutine.yield()
		end

		-- Yield has concluded, we now control the thread
		entry.Locked = true
		entry.Owner = currentThread
		entry.Depth = 1
		entry.OriginTraceback = traceback

		startHoldTimer(entry, player, expectedMaxRuntimeSeconds)
	end

	local function release(entry: MutexEntry, player: Player?)
		clearHoldTimer(entry)
		entry.Depth = 0
		entry.Owner = nil
		entry.OriginTraceback = nil

		if #entry.Queue > 0 then
			local nextThread = table.remove(entry.Queue, 1)
			if nextThread then
				-- Ownership transfers when nextThread continues after yield
				entry.Locked = true
				coroutine.resume(nextThread)
				return
			end
		end

		entry.Locked = false
		if player then
			playerEntries[player] = nil
		end
	end

	local function unlock(player: Player?)
		local currentThread = coroutine.running()
		local entry = if player then playerEntries[player] else global
		assert(entry ~= nil and entry.Locked, "Cannot unlock an already unlocked mutex")
		assert(entry.Owner == currentThread, "Cannot unlock mutex from a different thread")

		-- Handle depth if necessary
		if entry.Depth > 1 then
			entry.Depth -= 1
			return
		end

		release(entry, player)
	end

	local function wrap<A..., R...>(expectedMaxRuntimeSeconds: number?, player: Player?, traceback: string, func: (Types.Confirm, A...) -> R..., ...: A...): (boolean, R...)
		local currentThread = coroutine.running()
		local entry = if player then playerEntries[player] else global
		local alreadyOwned = entry ~= nil and entry.Locked and entry.Owner == currentThread

		if not alreadyOwned then
			lock(expectedMaxRuntimeSeconds, player, traceback)
		end

		local args: {any} = {...}
		local results: {any} = {false, "Silent assertion failed."}

		local invoke = func :: (Types.Confirm, ...any) -> ...any
		local thread = task.spawn(function()
			results = {pcall(invoke, silentAssert, unpack(args))}
			task.spawn(assert, results[1], `{tostring(results[2])}\n\nTraceback originated from {describe(player)} at:\n{traceback}`)
		end)

		while coroutine.status(thread) ~= "dead" do
			task.wait()
		end

		if not alreadyOwned then
			unlock(player)
		end

		return unpack(results)
	end

	local function releaseOwnedBy(owner: thread)
		if global.Locked and global.Owner == owner then
			release(global, nil)
		end
		for player, entry in playerEntries do
			if entry.Locked and entry.Owner == owner then
				release(entry, player)
			end
		end
	end

	local mutex: Types.Mutex = {
		Lock = function(self: Types.Mutex, expectedMaxRuntimeSeconds: number?, player: Player?)
			lock(expectedMaxRuntimeSeconds, player, getTracebackFirstLine())
		end,
		Unlock = function(self: Types.Mutex, player: Player?)
			unlock(player)
		end,
		Wrap = function<A..., R...>(self: Types.Mutex, expectedMaxRuntimeSeconds: number?, func: (Types.Confirm, A...) -> R..., ...: A...): (boolean, R...)
			return wrap(expectedMaxRuntimeSeconds, nil, getTracebackFirstLine(), func, ...)
		end,
		WrapPlayer = function<A..., R...>(self: Types.Mutex, expectedMaxRuntimeSeconds: number?, player: Player, func: (Types.Confirm, A...) -> R..., ...: A...): (boolean, R...)
			return wrap(expectedMaxRuntimeSeconds, player, getTracebackFirstLine(), func, ...)
		end
	}
	return mutex, releaseOwnedBy
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

		local service = definition :: fish.RegisteredService

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
			Instance = scriptInstance,
			Name = name
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

	While `self.confirm()` is enabled, client functions run on their own thread so they can be stopped silently.
	Because of how `self.confirm()` is implemented, errors have to be intercepted on the server side instead of
	being sent to the client directly. If this behavior is undesired and the usage of `self.confirm()` and locks
	held by `self.Mutex` being automatically released when the thread ends can be removed, pass `true` to disable both.

	@param disableConfirmAndMutexSafety boolean? -- Whether self.confirm() should be disabled, and whether locks held by self.Mutex won't automatically be released if an error occurs before self.Mutex:Unlock() is called
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
		local hasPriority: {fish.RegisteredService} = {}
		local noPriority: {fish.RegisteredService} = {}
		for _, service in services do
			if service.LoadPriority then
				table.insert(hasPriority, service)
			else
				table.insert(noPriority, service)
			end
		end
		table.sort(hasPriority, function(a: fish.RegisteredService, b: fish.RegisteredService)
			return (a.LoadPriority :: number) > (b.LoadPriority :: number)
		end)
		
		local sortedServices: {fish.RegisteredService} = {}
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

			-- Every "self" given to a client function, used to detect calls made from another client function
			local injectedSelves: {[any]: true} = setmetatable({}, { __mode = "k" }) :: any

			-- Wrap function to alter parameter functionality with player
			local function wrapFunction<K, V>(func: (...any) -> (), label: string)
				local mutex, releaseMutexOwnedBy = createMutex(label)
				return function(self: {[K]: V}, ...)
					-- Calls from the client pass the player first, calls from self:OtherClientFunction() already have it in self
					local player: Player
					local args: {any}
					if injectedSelves[self] then
						player = (self :: any).Player
						args = {...}
					else
						player = ...
						args = {select(2, ...)}
					end

					-- Create a local copy of "self" and inject "player" into it
					local localSelf = {}
					for k, v in self do
						localSelf[k] = v
					end
					localSelf.Player = player
					injectedSelves[localSelf] = true

					-- Inject the mutex
					localSelf.Mutex = mutex

					-- Disable confirm and mutex safety if asked
					if disableConfirmAndMutexSafety then
						localSelf.confirm = function()
							error("self.confirm() has been disabled. See fish.start()'s arguments to change this behavior.")
						end

						local returnValues = {func(localSelf, unpack(args))}

						releaseMutexOwnedBy(coroutine.running())

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
					local thread = task.spawn(function()
						if RunService:IsStudio() then
							returnValues = {func(localSelf, unpack(args))}
						else
							local success, err = pcall(function()
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

					releaseMutexOwnedBy(thread)
					
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

					local metadata = assert(service.__fishMetadata)
					local comm = ServerComm.new(servicesFolder, metadata.Name) :: any
					for k, v in client do
						if type(v) == "function" then
							client[k] = wrapFunction(v, `{metadata.Name}.{k}`)
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
									local wrappedFunction = wrapFunction(sv :: (...any) -> any, `{metadata.Name}.Signal.{sk}`);
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
					local serviceFolder = assert(servicesFolder:FindFirstChild(metadata.Name) :: Folder?)
					local serviceScriptInstance: ModuleScript = metadata.Instance
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
		return Promise.fromEvent(startedSignal :: PromiseEvent<>)
	end
end

return Server