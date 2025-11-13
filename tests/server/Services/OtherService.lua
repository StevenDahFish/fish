--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Core
local fish = require(ReplicatedStorage.Packages.fish); fish = fish.Server
local OtherService = {Client = {Signal = {}}}

--// Dependencies

--// Constants

--// Variables

--// Client Events

--// Functions
function OtherService.SayHello(self: self)
	print("Hello from OtherService!")
end

function OtherService.Start(self: self)
	warn("OtherService started!")
end

type self = typeof(OtherService)
type client = typeof(OtherService.Client)
type clientSignal = typeof(OtherService.Client.Signal)
export type reference = fish.ServiceToReference<client>
return fish.service(script, OtherService)