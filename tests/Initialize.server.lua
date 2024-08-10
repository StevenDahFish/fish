local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local fish = require(ReplicatedStorage.Packages.fish).Server

fish.serviceDeep(ServerStorage.Server.Services)
fish.start()