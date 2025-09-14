---
title: Getting Started
sidebar_position: 2
---

## Tutorial Video
This video has been created to help with every aspect of the process for setting up the fish framework and utilizing it to reach all of its possibilities!

~~**Watch the tutorial here!**~~ The tutorial has not been created yet, coming soon!

## Prerequisites
* Knowledge of [Wally](https://wally.run) and [Rojo](https://rojo.space)
* Knowledge of how to use [Luau types](https://luau.org/)
* Usage of a **Luau Language Server** in strict typed mode `--!strict`

This framework depends on typing, and a lot of design decisions have been made with using types in mind. If you do not see the need to use types, it's recommended to use another framework that would match your goals.

This documentation has been written with the assumption that you are using [VSCode](https://code.visualstudio.com/) with the [Luau LSP](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp) extension.

## Installation
### Wally & Rojo workflow
1. Add fish as a Wally dependency (e.g. `fish = "stevendahfish/fish@^1"`)
1. Add other dependencies to Wally as well (see [Dependencies](#dependencies)) 
1. Use Rojo to point the Wally packages to ReplicatedStorage.
1. ⚠️ Use [wally-package-types](faq#how-to-use-wally-package-types) to allow proper typing. **(IMPORTANT!)**

#### Dependencies
1. **Promise**
	* `Promise = "stevendahfish/typed-promise@^4"`
	* Mandatory for defining types for client functions in services
	* I've published onto Wally a typed version of evaera's [Promise](https://eryn.io/roblox-lua-promise/api/Promise/) package which should be used here
2. **t**
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
ServerScriptService
└── 🗎 Initialize.lua

ServerStorage
└── 🗀 Server
    └── 🗀 Services

StarterPlayer
└── StarterPlayerScripts
    └── 🗎 Initialize.lua
    └── 🗀 Client
        └── 🗀 Controllers
```

Initialize the server in `ServerScriptService > Initialize.lua`:
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local fish = require(ReplicatedStorage.Packages.fish)
fish.serviceDeep(ServerStorage.Server.Services)
fish.start()
```

Initialize the client as well in `StarterPlayer > StarterPlayerScripts > Initialize.lua`:
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local fish = require(ReplicatedStorage.Packages.fish)
fish.controllerDeep(Players.LocalPlayer.PlayerScripts.Client.Controllers)
fish.start()
```
## What's next?
See [Services](services) to see how to create a service.