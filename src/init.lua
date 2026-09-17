const RunService = game:GetService("RunService")
const Types = require(script.Types)

if RunService:IsClient() then
	local serverInstance = script:FindFirstChild("Server")
	if serverInstance then
		serverInstance:Destroy()
		serverInstance = script.Types:Clone()
		serverInstance.Name = "Server"
		serverInstance.Parent = script
	end
end

--[=[
	@type self<C,S> C & { Player: Player, Server: S, Mutex: Mutex, confirm: Confirm }
	@within Types
	Type used to describe the `self` object in Client functions.
	Each client function has its own [Mutex], with a global lock and one lock per player.
	```lua
	function MyService.Client.PrintPlayer(self: fish.self<client, server>)
		print(self.Player)
		
		--> Mutex with locking & unlocking
		self.Mutex:Lock()
		-- Run critical section
		self.Mutex:Unlock()

		--> Locking is re-entrant; this only releases once the matching Unlock has run
		self.Mutex:Lock()
		self.Mutex:Unlock()
		self.Mutex:Unlock()

		--> Locking this player only, warning if the lock is held for longer than 5 seconds
		self.Mutex:Lock(5, self.Player)
		-- Run critical section
		self.Mutex:Unlock(self.Player)
		
		--> Mutex with wrapping; the wrapped function runs on its own thread and is given its own silent assert
		local success, result = self.Mutex:Wrap(nil, function(confirm, parameter)
			-- Run critical section
			return parameter
		end, 1)
		print(success, result) --> Output: true, 1

		--> Silent assert (stops the current thread from continuing, equivalent to a return statement)
		self.confirm(success)
		print("This print statement won't run if success == false!")
	end
	```
]=]
export type self<C, S> = C & {
	Player: Player,
	Server: S,
	Mutex: Types.Mutex,
	confirm: Types.Confirm
};

--[=[
	@type ServiceToReference<T> {[any]: ToClient<type>}
	@within Types
	A type used to wrap an entire service's client table with ToClient<type>
]=]
export type ServiceToReference<T> = Types.ServiceToReference<T>

return {
	Server = require(script.Server),
	Client = require(script.Client)
}