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
	@type self<C,S> C & { Player: Player, Server: S, [any]: any }
	@within Types
	Type used to describe the `self` object in Client functions
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

--[=[
	@ignore
	@class ClientRemoteSignal
	@client
	Created via `ClientComm:GetSignal()`.
]=]
export type ClientRemoteSignal = DependencyTypes.ClientRemoteSignal

--[=[
	@class ClientRemoteProperty
	@client
	Created via `ClientComm:GetProperty()`.
]=]
export type ClientRemoteProperty = DependencyTypes.ClientRemoteProperty

return {
	Server = require(script.Server),
	Client = require(script.Client)
}