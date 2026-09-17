---
title: Advanced Features
sidebar_position: 1
---

There are features baked into fish by default which can help with developing your game.

## Obfuscation
You can obfuscate all **framework references**, including services, controllers, and any remote events/function instances that were created from the framework. This will make it more of a nuisance for exploiters to create cheats and make it harder to find a way to break your game.
:::warning WARNING
**This does not make your game exploit-proof.** No guarantees are made that this will prevent anything other than wasting time for cheaters attempting to infiltrate your game. You must ensure your game logic is secure and you validate all client actions accordingly for any chance of security.
:::
Enable obfuscation by passing `true` as the first parameter into `fish.start()` on the client.
```luau {5}
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const fish = require(ReplicatedStorage.Packages.fish).Client

fish.controllerDeep(script.Parent.Controllers)
fish.start(true)
```
:::info
### Side Effects
* By enabling obfuscation, you will no longer be able to bypass [cyclic dependencies](../faq.md#cyclic-dependencies) as attempting to require another fish module after `fish.start()` is ran will result in an error.
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

## confirm
This is a drop-in replacement for luau's `assert()` function, where the difference is instead of throwing an error, it'll simply act like a return statement and prevent further code execution. If the argument passed in is a truthy value, it'll pass and return that value, otherwise it will fail. This is useful in conjunction with [t](../getting-started.md#dependencies) when validating types or just when you need to validate concisely without the need to log if it failed. The intended purpose is to help prevent unnecessary error logs from appearing within a game's analytics page under Error Report in the Creator Dashboard, but of course this can be used for any purpose.

This has been implemented into all [service client functions](../services.md#adding-client-functions-to-a-service) and [service client signals](../services.md#signals) and can be used by accessing `self.confirm()`. See an example of how it is used [here](/api/Types#self<C,S>).
```luau
function MyService.Client.SetName(self: fish.self<client, self>, name: string?)
	const validName = self.confirm(name) -- the type of validName is string instead of string?
	print(self.Player.Name .. " set their name to " .. validName)
end
```

### Disabling confirm
In order for `self.confirm()` to work, every client function runs on its own thread so it can be stopped silently. Because of this, errors from client functions have to be intercepted on the server instead of being sent to the client directly. This also allows fish to automatically release any [Mutex](mutex.md#automatic-unlocking) locks that are still held when the thread ends.

If this behavior is undesired and you don't need `self.confirm()` or locks held by `self.Mutex` being automatically released when the thread ends, you can disable both by passing `true` as the first parameter into `fish.start()` on the server.
```luau {5}
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const fish = require(ReplicatedStorage.Packages.fish).Server

fish.serviceDeep(script.Parent.Services)
fish.start(true)
```
:::caution
By disabling this, you lose both of the following:
* `self.confirm()` will throw an error when used.
* Locks held by `self.Mutex` will **not** be automatically released if an error occurs before they are unlocked.
:::

## Mutex
A [Mutex](https://en.wikipedia.org/wiki/Mutual_exclusion) is built into all [service client functions](../services.md#adding-client-functions-to-a-service) and [service client signals](../services.md#signals). You can access it by using `self.Mutex`. See the [Mutex](mutex.md) page for how to use it.
