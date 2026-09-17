---
title: Controllers
sidebar_position: 4
---

## Creating a Controller
A controller is a client module to handle an aspect of your game. Start by importing the client section of fish and creating an empty table to represent your controller.
```luau
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
const MyController = {}
```
Similar to services, a start function should be defined as apart of the controller table which gets ran on framework start. Define it with dot notation and pass in the `self` type to allow full autocomplete. (*this type is defined in the next code block*)
```luau
function MyController.Start(self: self)
	print("MyController has been started!")
end
```
Finally, define the `self` type and return the controller by defining it with fish. The name of the controller will be the name of the script.
```luau
type self = typeof(MyController)
return fish.controller(script, MyController)
```
:::tip Snippet
**[fishclient](snippets/#fish-client) (fish client)**<br/>Initializes a controller
:::
### Load Priority
**Controllers are loaded in an arbitrary order unless otherwise specified**. This works the same way it does in services by adding the `LoadPriority` property to the controller table, see the [documentation here](services#load-priority).
```luau
const MyController = {LoadPriority = 10}
```

## Public functions & signals
These work the same way they do in services, see the [documentation here](services#public-functions).
:::tip Snippet
**[fc](snippets/#fish-controller-reference) (fish controller reference)**<br/>Creates a controller reference
:::

## Server Communication
Services are able to be communicated with through its functions, signals, and properties that it exposes to the client. If a service does not expose any of these, its existance is not known to the client and attempting to reference that service will result in a runtime error.

To import a service, you'll want to simply require it in the location that you store them. In this example, we'll be following the same path shown in [Basic Usage](getting-started#basic-usage) (`ServerStorage > Server > Services`). However, this will not give the correct typing as you'll be seeing the types as if you were viewing this from a server context. To fix this, we redefine the variable while casting it to the `reference` type that was explained in the [services documentation](services#reference). The result looks like this:
```luau
const MyService = require("@game/ServerStorage/Server/Services/MyService"); const MyService = (MyService :: unknown) :: MyService.reference
```
:::tip Snippet
**[fsc](snippets/#fish-service-reference-client) (fish service reference client)**<br/>Creates a service reference for the client
:::
## Full Example
A few examples involving functions, signals, and properties are shown below.
```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
const MyController = {}

-- Dependencies
const MyService = require("@game/ServerStorage/Server/Services/MyService"); const MyService = (MyService :: unknown) :: MyService.reference

function MyController.Start(self: self)
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

type self = typeof(MyController)
return fish.controller(script, MyController)
```
