---
title: Getting Started
sidebar_position: 2
---

## Prerequisites
* Knowledge of [Wally](https://wally.run) and [Rojo](https://rojo.space)
* Knowledge of how to use [Luau types](https://luau.org/)
* Knowledge of how to use [Luau's new solver](https://devforum.roblox.com/t/new-type-solver-beta/3155804)
* Usage of a **Luau Language Server** in strict typed mode `--!strict` and with the new solver

This framework depends on typing, and a lot of design decisions have been made with using types in mind. If you do not see the need to use types, it's recommended to use another framework that would match your goals.

This documentation has been written with the assumption that you are using [VSCode](https://code.visualstudio.com/) with the [Luau LSP](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp) extension.

:::tip
Coming from v1? See [Migrating from v1](migrating-from-v1) to see what has changed and how to update your project.
:::

## Installation
### Wally & Rojo workflow
1. Add fish as a Wally dependency (e.g. `fish = "stevendahfish/fish@^2"`)
1. Add other dependencies to Wally as well (see [Dependencies](#dependencies))
1. Use Rojo to point the Wally packages to ReplicatedStorage.
1. ⚠️ Use [wally-package-types](faq#how-to-use-wally-package-types) to allow proper typing. **(IMPORTANT!)**

#### Dependencies
1. **t**
	* `t = "osyrisrblx/t@^3"`
	* Highly recommended for defining type security when handling responses from the client for client functions in services

### Studio workflow

A workflow for studio has not been a priority for fish yet. It is highly recommended you use Wally & Rojo at this moment.

## Structure
The structure of fish is based around the hierarchy of Services (server modules) and Controllers (client modules). Services are able to call each other and communicate directly using requires, as well as controllers between each other. However, services are unable to communicate directly with controllers. Instead, events can be fired to clients which any controller can listen to.

![Communication structure](/structure.png)

## Basic Usage
First, you want to create a basic structure for where to store services and controllers.

```
ServerStorage
└── 🗀 Server
    └── 🗀 Services
    └── 🗎 Initialize.lua

ReplicatedStorage
└── 🗀 Client
    └── 🗀 Controllers
    └── 🗎 Initialize.lua
```

Example of `default.project.json`:
```json
{
	"name": "my-project",
	"emitLegacyScripts": false,
	"tree": {
		"$className": "DataModel",

		"ReplicatedStorage": {
			"$className": "ReplicatedStorage",
			"Packages": {
				"$path": "Packages"
			},
			"Client": {
				"$path": "src/client"
			}
		},

		"ServerStorage": {
			"$className": "ServerStorage",
			"Server": {
				"$path": "src/server"
			}
		}
	}
}
```

Initialize the server in `ServerStorage > Server > Initialize.lua` with the `RunContext` set to `Server`:
```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const fish = require(ReplicatedStorage.Packages.fish).Server

fish.serviceDeep(script.Parent.Services)
fish.start()
```

Initialize the client as well in `ReplicatedStorage > Client > Initialize.lua` with the `RunContext` set to `Client`:
```luau
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const fish = require(ReplicatedStorage.Packages.fish).Client

fish.controllerDeep(script.Parent.Controllers)
fish.start()
```
## What's next?
See [Services](services) to see how to create a service.
