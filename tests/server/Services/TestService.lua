--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local t = require(ReplicatedStorage.Packages.t)
local TestService = {Client = {}}

--// Dependencies
local Promise = require(ReplicatedStorage.Packages.Promise)
local ExampleModule = require(ServerStorage.Server.Modules.ExampleModule)
local OtherService = require(script.Parent.OtherService)

--// Constants

--// Variables

--// Client Events
TestService.Client.SayHello = fish.signal()

--// Functions
function TestService.Client.SayHelloPublic(self: fish.self<sclient, server>, yes: string): boolean
	assert(t.tuple(t.string)(yes))
	warn("== SayHelloPublic called == ")
	print("Hello public!")
	print("from:", self.Player)
	return true
end

function TestService:Start()
	warn("TestService started!")
	OtherService:SayHello()
	Players.PlayerAdded:Connect(function(player)
		TestService.Client.SayHello:Fire(player)
	end)
end

--// Mapping
export type client = {
	SayHello: fish.ClientRemoteSignal,
	SayHelloPublic: (self: any, yes: string) -> Promise.TypedPromise<boolean>
}

type server = typeof(TestService)
type sclient = typeof(TestService.Client)
return fish.service("TestService", TestService)