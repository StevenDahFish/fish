---
title: Advanced Features
sidebar_position: 6
---

There are features baked into fish by default which can help with developing your game.

## Obfuscation
You can obfuscate all **framework references**, including services, controllers, and any remote events/function instances that were created from the framework. This will make it more of a nuisance for exploiters to create cheats and make it harder to find a way to break your game.
:::warning WARNING
**This does not make your game exploit-proof.** No guarantees are made that this will prevent anything other than wasting time for cheaters attempting to infiltrate your game. You must ensure your game logic is secure and you validate all client actions accordingly for any chance of security.
:::
Enable obfuscation by passing `true` as the first parameter into `fish.start()` on the client.
```luau {6}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local fish = require(ReplicatedStorage.Packages.fish)
fish.controllerDeep(Players.LocalPlayer.PlayerScripts.Client.Controllers)
fish.start(true)
```
:::info
### Side Effects
* By enabling obfuscation, you will no longer be able to bypass [cyclic dependencies](faq/#cyclic-dependencies) as attempting to require another fish module after `fish.start()` is ran will result in an error.
* You will lose the abilty to know what controller gave an error (*during playtests out of studio*) due to the script name being randomized. Services remain intact and will still say their name correctly.
:::

## @load
This feature determines whether a service/controller will be loaded based on defined conditions. Normally, all modules passed in to `fish.serviceDeep()` or `fish.controllerDeep()` will be required and loaded into to the framework. However, you can create a new module script in the parent of the service/controller named `@load` that returns a function that upon being called, returns a boolean. This module will be used to check against all other services/controllers in the same directory before allowing that module to be loaded into the framework. This can be useful for scenarios where you only want to load a service/controller in a specific subplace, such as the lobby.

Here is an example of what a `@load` module looks like. This would only load the services in the same folder if the current place id is equal to the lobby's place id, or if the service is named "ImportantService."
```luau
return function(module: ModuleScript): boolean
	return game.PlaceId == LOBBY_PLACE_ID or module.Name == "ImportantService"
end
```
In this example hierarchy, every service within this folder will be checked against the return value of the `@load`.
```
ServerStorage
└── 🗀 Server
    └── 🗀 Services
        └── 🗎 @load.lua
        └── 🗎 MyService.lua
        └── 🗎 ImportantService.lua
```

## Mutex
[Mia Vince's](https://wally.run/package/notfenv/mutex) implementation of [Mutex](https://en.wikipedia.org/wiki/Mutual_exclusion) has been implemented into all [service client functions](services/#adding-client-functions-to-a-service) and [service client signals](services/#signals). You can access it by using `self.Mutex` and see examples of how to use it [here](/api/Types#self<C,S>).

## confirm
This is a drop-in replacement for luau's `assert()` function, where the difference is instead of throwing an error, it'll simply act like a return statement and prevent further code execution. If the argument passed in is a truthy value, it'll pass, otherwise it will fail. This is useful in conjunction with [t](getting-started/#dependencies) when validating types or just when you need to validate concisely without the need to log if it failed. The intended purpose is to help prevent unnecessary error logs from appearing within a game's analytics page under Error Report in the Creator Dashboard, but of course this can be used for any purpose.

This has been implemented into all [service client functions](services/#adding-client-functions-to-a-service) and [service client signals](services/#signals) and can be used by accessing `self.confirm()`. See an example of how it is used [here](/api/Types#self<C,S>).