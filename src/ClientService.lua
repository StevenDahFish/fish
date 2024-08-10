local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fish = require(ReplicatedStorage.Packages.fish).Client

return fish.service(script.Name)