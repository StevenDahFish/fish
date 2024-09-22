local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local DependencyTypes = require(script.DependencyTypes)

if RunService:IsClient() and script:FindFirstChild("Server") then
	local serverInstance = script:FindFirstChild("Server")
	if serverInstance and RunService:IsRunning() then
		serverInstance:Destroy()
		serverInstance = script.Types:Clone()
		serverInstance.Name = "Server"
		serverInstance.Parent = script
	end

	-- Initialize server-like structure
	local serverFolder = Instance.new("Folder", ServerStorage)
	serverFolder.Name = "Server"
	local services = Instance.new("Folder", serverFolder)
	services.Name = "Services"
end

--[=[
	@type self<C,S> C & { Player: Player, Mutex: { Lock: (self) -> (), Unlock: (self) -> (), Wrap: (self, (...any) -> (), ...any) -> (boolean, ...any) }, Server: S, [any]: any }
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
	end
	```
]=]
export type self<C, S> = C & {
	Player: Player,
	Mutex: {
		Lock: (self: any) -> (),
		Unlock: (self: any) -> (),
		Wrap: (self: any, (...any) -> (), ...any) -> (boolean, ...any)
	},
	Server: S,
	[any]: any
};

--[=[
	@ignore
	@class ClientRemoteSignal
	@client
	Created via `ClientComm:GetSignal()`.
]=]
export type ClientRemoteSignal = DependencyTypes.ClientRemoteSignal

--[=[
	@ignore
	@class ClientRemoteProperty
	@client
	Created via `ClientComm:GetProperty()`.
]=]
export type ClientRemoteProperty = DependencyTypes.ClientRemoteProperty

return {
	Server = require(script.Server),
	Client = require(script.Client)
}