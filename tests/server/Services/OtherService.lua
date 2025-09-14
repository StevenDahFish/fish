--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local OtherService = {Client = {Signal = {}}}

--// Dependencies

--// Constants

--// Variables

--// Client Events

--// Functions
function OtherService.SayHello(self: server)
	print("Hello from OtherService!")
end

function OtherService.Start(self: server)
	warn("OtherService started!")
end

--// Mapping
export type client = {
	
} & typeof(OtherService.Client)

type self = server
type server = {Start: never} & typeof(OtherService)
type sclient = typeof(OtherService.Client)
return fish.service("OtherService", OtherService, script)