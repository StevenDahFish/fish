---
title: FAQ
sidebar_position: 7
---

### How to use wally-package-types?
[wally-package-types](https://github.com/JohnnyMorganz/wally-package-types) is required in order to properly export the types from [wally](https://wally.run) packages and make them accessible. fish exposes many types which are necessary to use the framework, therefore this tool is needed.

1. [Install](https://github.com/JohnnyMorganz/wally-package-types/releases) the latest version from releases for your operating system and add it to your [PATH](https://learn.sparkfun.com/tutorials/configuring-the-path-system-variable/all).
1. Run `wally install` first to install all of your packages.
1. Generate a sourcemap using `rojo sourcemap --output sourcemap.json`
1. Run `wally-package-types --sourcemap sourcemap.json Packages` to add types to your packages.

### Why is fish server imported like that?
For reference, this question is referencing the import of fish on the server:
```lua
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
```

This is due to how Luau reads types when importing modules. In reality, the fish module returns this:
```lua
	return {
		Server = {...} -- functions such as .start(), .service(), .property(), etc.
		Client = {...} -- functions such as .start(), .controller(), .onStart(), etc.
	}
```
Within the fish module, it exports the types necessary such as `fish.self` or `fish.ClientRemoteProperty`. However, when you set the variable to equal the Server section of fish directly (`require(ReplicatedStorage.Packages.fish).Server`), there are no types that it can read as it's just reading a table. Therefore to fix this, we simply set the fish variable to equal the module which has the exported types, then we redefine the variable to equal it's own module then reference the Server section, allowing the language server to still remember the types while referring to the Server section as needed.

This isn't done for the client momentarily as there are no types necessary that the client needs to access, so we can just import it normally without having to do this hack.

### Why do I get an error when trying to import a service from a controller?
Make sure you import it correctly as shown [here](controllers#server-communication). If you are sure that you have imported it like so, make sure that the service is not just returning the service table and is returning `fish.service()` as shown [here](services#final-result).

### What are some limitations of fish?
#### Cyclic Dependencies
When requiring two services in each other (**AService** requires **BService** which requires **AService** and so on...), this create a cyclic dependency. Unfortunately, due to how requiring modules works with Luau, it's not possible to avoid this error. The only solution is to cast the type `any` in one of the services, removing its typing for that service in the process. The service must also be required outside of the global context (ex. within the Start function) to prevent runtime errors.

```lua
--==============--
-- ServiceA.lua --
--==============--

-- Core
local ServiceA = {}

-- Dependencies
local ServiceB = require(script.Parent.ServiceB)

return fish.service("ServiceA", ServiceA, script)

--==============--
-- ServiceB.lua --
--==============--

-- Core
local ServiceB = {}

function ServiceB:Start()
	local ServiceA = require(script.Parent.ServiceA) :: any -- casting type "any"
end

return fish.service("ServiceB", ServiceB, script)
```

![A flowchart showcasing how cyclic dependencies cause an issue.](/cyclic_dependency.png)