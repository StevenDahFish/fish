--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish).Client
local TestController = {}

--// Dependencies
local TestService = require(ServerStorage.Server.Services.TestService); local TestService: TestService.client = TestService
local ExampleController = require(script.Parent.ExampleController)

--// Constants

--// Variables

--// Functions
function TestController:Start()
	warn("TestController started!")
	ExampleController:OtherFunction()
	TestService:SayHelloPublic("yes"):andThen(function(boolean)
		print("Response from TestService:")
		print(boolean)
	end)
	TestService.SayHello:Connect(function()
		print("I was told to say hello!")
		TestService:SayHelloPublic(1 :: any) -- Invalid type
	end)
end

return fish.controller("TestController", TestController)