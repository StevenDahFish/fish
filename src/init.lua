local RunService = game:GetService("RunService")
local Types = require(script.Types)

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
	@type self<C,S> C & { Player: Player, Server: S, Mutex: { Lock: (self, Player) -> (), Unlock: (self, Player) -> (), Wrap: <A...>(self, (A...) -> (...any), A...) -> (boolean, ...unknown), WrapPlayer: <A...>(self, Player, (A...) -> (...any), A...) -> (boolean, ...unknown) }, confirm: <T>(value: T?) -> T }
	@within Types
	Type used to describe the `self` object in Client functions
	```lua
	function MyService.Client.PrintPlayer(self: fish.self<client, server>)
		print(self.Player)
		
		--> Mutex with locking & unlocking
		self.Mutex:Lock()
		-- Run critical section
		self.Mutex:Unlock()
		
		--> Mutex with wrapping
		local success, result = self.Mutex:Wrap(function(parameter)
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
	Mutex: {
		Lock: (self: any, player: Player?) -> (),
		Unlock: (self: any, player: Player?) -> (),
		Wrap: <A...>(self: any, func: (A...) -> (...any), A...) -> (boolean, ...unknown),
		WrapPlayer: <A...>(self: any, player: Player, func: (A...) -> (...any), A...) -> (boolean, ...unknown)
	},
	confirm: <T>(value: T?) -> T
};

--[=[
	@ignore
	@type ServiceToReference<T> {[any]: ToClient<type>}
	@within TypeFunctions
	A type used to wrap an entire service's client table with ToClient<type>
]=]
export type ServiceToReference<T> = Types.ServiceToReference<T>

return {
	Server = require(script.Server),
	Client = require(script.Client)
}