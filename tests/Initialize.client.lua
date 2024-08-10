local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fish = require(ReplicatedStorage.Packages.fish).Client

fish.controllerDeep(script.Parent.Client.Controllers)
fish.start()