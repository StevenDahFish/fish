---
title: FAQ
sidebar_position: 8
---

### How to use wally-package-types?
:::warning
As of **September 16th, 2026**, wally-package-types has not published a new release that updates its internals to be able to understand `const` statements (the fix for this is stuck in their backlog). Because of this, using their latest release on a fish v2 project will result in type errors.

However, I have manually compiled an updated version that fixes this problem. Use these downloads for now until their project gets a new release.

* [**wally-package-types-linux-aarch64.zip**](https://cdn.stevendah.fish/fish/wally-package-types-linux-aarch64.zip)
* [**wally-package-types-linux-x86_64.zip**](https://cdn.stevendah.fish/fish/wally-package-types-linux-x86_64.zip)
* [**wally-package-types-macos-aarch64.zip**](https://cdn.stevendah.fish/fish/wally-package-types-macos-aarch64.zip)
* [**wally-package-types-macos.zip**](https://cdn.stevendah.fish/fish/wally-package-types-macos.zip)
* [**wally-package-types-win64.zip**](https://cdn.stevendah.fish/fish/wally-package-types-win64.zip)
:::
[wally-package-types](https://github.com/JohnnyMorganz/wally-package-types) is required in order to properly export the types from [wally](https://wally.run) packages and make them accessible. fish exposes many types which are necessary to use the framework, therefore this tool is needed.

<!-- 1. [Install](https://github.com/JohnnyMorganz/wally-package-types/releases) the latest version from releases for your operating system and add it to your [PATH](https://learn.sparkfun.com/tutorials/configuring-the-path-system-variable/all). -->
1. **Install** (from the warning notice above) the latest version from releases for your operating system and add it to your [PATH](https://learn.sparkfun.com/tutorials/configuring-the-path-system-variable/all).
1. Run `wally install` first to install all of your packages.
1. Generate a sourcemap using `rojo sourcemap --output sourcemap.json`
1. Run `wally-package-types --sourcemap sourcemap.json Packages` to add types to your packages.

### Why is fish server/client imported like that?
For clarification, this question is referencing the import of the fish module:
```luau
-- on the server
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server

-- on the client
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
```

This is due to how Luau reads types when importing modules. In reality, the fish module returns this:
```luau
	return {
		Server = {...} -- functions such as .start(), .service(), .property(), etc.
		Client = {...} -- functions such as .start(), .controller(), .onStart(), etc.
	}
```
Within the fish module, it exports the types necessary such as `fish.self` or `fish.ServiceToReference`. However, when you set the variable to equal the Server/Client section of fish directly (`require(ReplicatedStorage.Packages.fish).Server`), there are no types that it can read as it's just reading a table. Therefore to fix this, we simply set the fish variable to equal the module which has the exported types, then we redefine the variable with the same name to equal the Server/Client section, allowing the language server to still remember the types while referring to the Server/Client section as needed.

### Why do I get an error when trying to import a service from a controller?
Make sure you import it correctly as shown [here](controllers#server-communication). If you are sure that you have imported it like so, make sure that the service is returning `fish.service()` as shown [here](services#final-result) and that the service has something in its Client table.

### Why do I get a warning that a service/controller took too long to be required?
If a service or controller takes more than 5 seconds to be required, a warning will be outputted. This usually means the module is waiting on something that will never finish, such as a [cyclic dependency](#cyclic-dependencies) or yielding code outside of the Start function.

### What are some limitations of fish?
#### Cyclic Dependencies
When requiring two services in each other (**AService** requires **BService** which requires **AService** and so on...), this create a cyclic dependency. Unfortunately, due to how requiring modules works with Luau, it's not possible to avoid this error. The only solution is to cast the type `any` in one of the services, removing its typing for that service in the process. The service must also be required outside of the global context (ex. within the Start function) to prevent runtime errors.

```luau
--==============--
-- ServiceA.lua --
--==============--

-- Core
const ServiceA = {}

-- Dependencies
const ServiceB = require("./ServiceB")

return fish.service(script, ServiceA)

--==============--
-- ServiceB.lua --
--==============--

-- Core
const ServiceB = {}

function ServiceB.Start()
	const ServiceA = require("./ServiceA") :: any -- casting type "any"
	-- this will not work if obfuscation is enabled! (see Advanced Features page)
end

return fish.service(script, ServiceB)
```

![A flowchart showcasing how cyclic dependencies cause an issue.](/cyclic_dependency.png)
