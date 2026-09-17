---
title: Migrating from v1
sidebar_position: 9
---

## Differences from v1
### Types & Syntax
* Luau's [new solver](https://devforum.roblox.com/t/new-type-solver-beta/3155804) is now required, and all examples use `const` and require by string.
* Services and controllers are now defined using `fish.service(script, MyService)` and `fish.controller(script, MyController)`. The name is taken from the script and casting to `fish.ServiceDef` or `fish.ControllerDef` is no longer needed.
* The `client` type (mapping) no longer needs to be written by hand. It has been replaced by the `reference` type, which is created for you using `fish.ServiceToReference`. See [Reference](services#reference).
* Services are now referenced on the client by casting to the `reference` type instead of the `client` type.
* The following types are no longer exported from fish:
	* `fish.ClientRemoteSignal`
	* `fish.ClientRemoteProperty`
	* `fish.ServiceDef`
	* `fish.ControllerDef`
* `self.confirm()` now removes `nil` from the type of the value it returns.

### Structure
* The client is now stored in `ReplicatedStorage > Client` instead of `StarterPlayer > StarterPlayerScripts`. See [Basic Usage](getting-started#basic-usage).
* Obfuscation no longer removes the client folder, as the client is no longer copied from `StarterPlayerScripts` into `PlayerScripts`.
* Services no longer need to be stored in `ServerStorage > Server > Services`. The client now recreates the same location that the service module is stored in on the server.
* Services can now use `LoadPriority` to specify a load order, which was previously only available for controllers. See [Load Priority](services#load-priority).

### Mutex
* Mutex is now built into fish instead of using [Mia Vince's](https://wally.run/package/notfenv/mutex) package.
* Each Mutex now has a global lock and a lock for each player. See [Mutex](advanced-features/mutex).
* `self.Mutex:Wrap()` now takes the expected max runtime as the first parameter, and passes a `confirm` into the wrapped function as its first parameter.
* `self.Mutex:WrapPlayer()` has been added.
* Locks still held when a client function ends are now automatically released.
* Warnings are now outputted when a lock is re-entered too many times, has too many threads waiting, or is held for longer than expected.
* `self.confirm()` and Mutex safety can now be disabled by passing `true` into `fish.start()` on the server. See [Disabling confirm](advanced-features#disabling-confirm).

## Migration Guide
### 1. Update fish
1. Update fish in your Wally dependencies to `fish = "stevendahfish/fish@^2"`
1. Run `wally install` and [wally-package-types](faq#how-to-use-wally-package-types) again.
1. Make sure your **Luau Language Server** is using the new solver.

### 2. Update Initialize scripts
Move your client into `ReplicatedStorage > Client` as shown in [Basic Usage](getting-started#basic-usage), and update both Initialize scripts.
```luau
-- Before (v1)
local fish = require(ReplicatedStorage.Packages.fish).Client
fish.controllerDeep(Players.LocalPlayer.PlayerScripts.Client.Controllers)
fish.start()

-- After (v2)
const fish = require(ReplicatedStorage.Packages.fish).Client
fish.controllerDeep(script.Parent.Controllers)
fish.start()
```

### 3. Update services
Update the fish import, remove the `client` mapping, and replace the types and return at the bottom of each service.
```luau
-- Before (v1)
local fish = require(ReplicatedStorage.Packages.fish); fish = fish.Server
local Promise = require(ReplicatedStorage.Packages.Promise)
local MyService = {Client = {Signal = {}}}

function MyService.Client.GetMoney(self: fish.self<sclient, self>): number
	return 100
end

-- Mapping
export type client = {
	GetMoney: (self: any) -> Promise.TypedPromise<number>
}

type self = typeof(MyService)
type sclient = typeof(MyService.Client)
type sclientsignal = typeof(MyService.Client.Signal)
return fish.service("MyService", MyService :: fish.ServiceDef, script)

-- After (v2)
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server
const MyService = {Client = {Signal = {}}}

function MyService.Client.GetMoney(self: fish.self<client, self>): number
	return 100
end

type self = typeof(MyService)
type client = typeof(MyService.Client)
type clientSignal = typeof(MyService.Client.Signal)
export type reference = fish.ServiceToReference<client>
return fish.service(script, MyService)
```
:::tip
The types `sclient` and `sclientsignal` have been renamed to `client` and `clientSignal` in the [snippets](snippets). Make sure to rename them in `fish.self<>` for each client function if you do the same.
:::

### 4. Update controllers
Update the fish import, the return at the bottom of each controller, and any service references.
```luau
-- Before (v1)
local fish = require(ReplicatedStorage.Packages.fish); fish = fish.Client
local MyController = {}

local MyService = require(ServerStorage.Server.Services.MyService); local MyService = MyService :: MyService.client

type self = typeof(MyController)
return fish.controller("MyController", MyController :: fish.ControllerDef, script)

-- After (v2)
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
const MyController = {}

const MyService = require("@game/ServerStorage/Server/Services/MyService"); const MyService = (MyService :: unknown) :: MyService.reference

type self = typeof(MyController)
return fish.controller(script, MyController)
```

### 5. Update Mutex usage
If you use `self.Mutex:Wrap()`, add the expected max runtime as the first parameter and `confirm` as the first parameter of the wrapped function.
```luau
-- Before (v1)
local success, result = self.Mutex:Wrap(function(parameter)
	return parameter
end, 1)

-- After (v2)
const success, result = self.Mutex:Wrap(nil, function(confirm, parameter)
	return parameter
end, 1)
```
:::caution
The wrapped function now runs on its own thread. See [Limitations](advanced-features/mutex#limitations) before using the same lock inside of a wrapped function.
:::
