--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish); fish = fish.Server
local t = require(ReplicatedStorage.Packages.t)
local TestService = {Client = {Signal = {}}}

--// Dependencies
local ExampleModule = require(ServerStorage.Server.Modules.ExampleModule)
local OtherService = require(script.Parent.OtherService)

--// Constants

--// Variables

--// Client Events
TestService.Client.SayHello = fish.signal()

--// Functions
function TestService.Client.SayHelloPublic(self: fish.self<client, self>, yes: string): boolean
	warn("== SayHelloPublic called == ")
	self.confirm(t.string(yes)) -- assert, but silently fails instead of throwing an error
	print("Hello public!")
	print("from:", self.Player)
	return true
end

function TestService.Client.Signal.SayNumber(self: fish.self<clientSignal, self>, number: number)
	warn("== Signal.SayNumber called == ")
	self.confirm(t.number(number))
	print(number)
	print("from:", self.Player)
end

function TestService.Start(self: self)
	warn("TestService started!")
	OtherService:SayHello()
	Players.PlayerAdded:Connect(function(player)
		self.Client.SayHello:Fire(player)
	end)
end

type self = typeof(TestService)
type client = typeof(TestService.Client)
type clientSignal = typeof(TestService.Client.Signal)
export type reference = fish.ServiceToReference<client>
return fish.service(script, TestService)