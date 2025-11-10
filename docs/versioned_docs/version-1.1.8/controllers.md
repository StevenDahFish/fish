---
title: Controllers
sidebar_position: 4
---

## Creating a Controller
A controller is a client module to handle an aspect of your game. Start by importing the client section of fish and creating an empty table to represent your controller.
```luau
local fish = require(ReplicatedStorage.Packages.fish); fish = fish.Client
local MyController = {}
```
Similar to services, a start function should be defined as apart of the controller table which gets ran on framework start. Define it with dot notation and pass in the `self` type to allow full autocomplete. (*this type is defined in the next code block*)
```luau
function MyController.Start(self: self)
	print("MyController has been started!")
end
```
:::note
**Controllers are loaded in an abitrary order**. Ensure when referencing other controllers, that it can run safely if it doesn't start at the same time. Using any public functions should be safe, assuming that any logic done inside these functions don't depend on its Start function running first. It's also convention to run most code in the Start function and *not* outside in the global context.
:::
Finally, define the `self` type and return the controller by defining it with fish.
```luau
type self = typeof(MyController)
return fish.controller("MyController", MyController :: fish.ControllerDef, script)
```
:::tip Snippet
**[fishclient](snippets/#fish-client) (fish client)**<br/>Initializes a controller
:::
## Public functions & signals
These work the same way they do in services, see the [documentation here](services#public-functions).

## Server Communication
Services are able to be communicated with through its functions, signals, and properties that it exposes to the client. If a service does not expose any of these, its existance is not known to the client and attempting to reference that service will result in a runtime error.

To import a service, you'll want to simply require it in the location that you store them. In this example, we'll be following the same path shown in [Basic Usage](getting-started#basic-usage) (`ServerStorage > Server > Services`). However, this will not give the correct typing as you'll be seeing the types as if you were viewing this from a server context. To fix this, we redefine the variable while assigning it the type of the `client` [mapping](services#mapping) that was explained in the services documentation. The result looks like this:
```luau
local MyService = require(ServerStorage.Server.Services.MyService); local MyService = MyService :: MyService.client
```
:::tip Snippet
**[fsc](snippets/#fish-service-reference-client) (fish service reference client)**<br/>Creates a service reference for the client
:::
## Full Example
A few examples involving functions, signals, and properties are shown below.
```luau
local fish = require(ReplicatedStorage.Packages.fish); fish = fish.Client
local MyController = {}

-- Dependencies
local MyService = require(ServerStorage.Server.Services.MyService); local MyService = MyService :: MyService.client

function MyController:Start()
	MyService:GetMoney():andThen(function(money)
		print("I have $" .. money)
	end)

	MyService.Announcement:Connect(function(message)
		print("Announcement from MyService:", message)
	end)

	MyService.AwesomeProperty:Observe(function(value)
		print("The awesome property has a value of: " .. value)
	end)
end

return fish.controller("MyController", MyController :: fish.ControllerDef, script)

```