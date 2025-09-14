--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish).Client
local ExampleController = {}

--// Dependencies

--// Constants

--// Variables

--// Functions
function ExampleController.OtherFunction(self: self)
	print("Used public OtherFunction()!")
end

function ExampleController.Start(self: self)
	warn("ExampleController started!")
end

type self = {Start: never} & typeof(ExampleController)
return fish.controller("ExampleController", ExampleController, script)