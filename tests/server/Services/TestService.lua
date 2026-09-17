--// Services
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

--// Core
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server
const t = require(ReplicatedStorage.Packages.t)
const TestService = {Client = {Signal = {}}}

--// Dependencies
const OtherService = require("./OtherService")
const ExampleModule = require(ServerStorage.Server.Modules.ExampleModule)

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