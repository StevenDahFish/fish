local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

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

return {
	Server = require(script.Server),
	Client = require(script.Client)
}