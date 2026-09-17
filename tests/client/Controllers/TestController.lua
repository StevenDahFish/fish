-- Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
const TestController = {}

-- Dependencies
const TestService = require("@game/ServerStorage/Server/Services/TestService"); const TestService = (TestService :: unknown) :: TestService.reference
const ExampleController = require("./ExampleController")

-- Variables

-- Functions
function TestController.Start(self: self)
	warn("TestController started!")
	ExampleController:OtherFunction()
	TestService:SayHelloPublic("yes"):andThen(function(boolean)
		print("Response from TestService:")
		print(boolean)
	end)
	TestService.SayHello:Connect(function()
		print("I was told to say hello!")
		TestService:SayHelloPublic(1 :: any) -- Invalid type, this would cause a silent fail on the server!
	end)
	TestService.SayNumber:Fire(123)
end

type self = typeof(ExampleController)
return fish.controller(script, TestController)