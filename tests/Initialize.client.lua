local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local fish = require(ReplicatedStorage.Packages.fish).Client

fish.controllerDeep(script.Parent.Client.Controllers)
fish.start()