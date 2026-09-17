-- Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
const ExampleController = {}

-- Dependencies

-- Variables

-- Functions
function ExampleController.OtherFunction(self: self)
	print("Used public OtherFunction()!")
end

function ExampleController.Start(self: self)
	warn("ExampleController started!")
end

type self = typeof(ExampleController)
return fish.controller(script, ExampleController)