--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local OtherService = {Client = {}}

--// Dependencies

--// Constants

--// Variables

--// Client Events

--// Functions
function OtherService:SayHello()
	print("Hello from OtherService!")
end

function OtherService:Start()
	warn("OtherService started!")
end

--// Mapping
export type client = {
	
} & typeof(OtherService.Client)

type server = typeof(OtherService)
type sclient = typeof(OtherService.Client)
return fish.service("OtherService", OtherService)