local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fish = require(ReplicatedStorage.Packages.fish).Server

fish.serviceDeep(script.Parent.Services)
fish.start()