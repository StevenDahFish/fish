--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local t = require(ReplicatedStorage.Packages.t)
local TestService = {Client = {Signal = {}}}

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
	warn("== SayHelloPublic called == ")
	self.confirm(t.string(yes)) -- assert, but silently fails instead of throwing an error
	print("Hello public!")
	print("from:", self.Player)
	return true
end

function TestService.Client.Signal.SayNumber(self: fish.self<sclientsignal, server>, number: number)
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

--// Mapping
export type client = {
	SayHello: fish.ClientRemoteSignal,
	SayHelloPublic: (self: any, yes: string) -> Promise.TypedPromise<boolean>,
	SayNumber: fish.ClientRemoteSignal
}

type self = server
type server = {Start: never} & typeof(TestService)
type sclient = typeof(TestService.Client)
type sclientsignal = typeof(TestService.Client.Signal)
return fish.service("TestService", TestService, script)