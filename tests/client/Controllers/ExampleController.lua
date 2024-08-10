--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish).Client
local ExampleController = {}

--// Dependencies

--// Constants

--// Variables

--// Functions
function ExampleController:OtherFunction()
	print("Used public OtherFunction()!")
end

function ExampleController:Start()
	warn("ExampleControlle started!")
end

return fish.controller("ExampleController", ExampleController)