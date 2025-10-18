---
title: Snippets
sidebar_position: 7
---

These snippets can help speed up workflow by allowing you to easily define entire services/controllers or components of these and focus on writing code! These are written for [VSCode](https://code.visualstudio.com/) and are usable in `File > Preferences > Configure Snippets > luau.json`.

### Cheat Sheet
* [`fishserver`](#fish-server)- Initializes a service
* [`fishclient`](#fish-client) - Initializes a controller
* [`ff`](#fish-function) - Creates a public function
* [`ffc`](#fish-function-client) - Create a public client function for a service
* [`ffcs`](#fish-function-client-signal) - Create a public client function signal for a service
* [`fss`](#fish-service-reference-server) - Creates a service reference for the server
* [`fsc`](#fish-service-reference-client) - Creates a service reference for the client
* [`fc`](#fish-controller-reference) - Creates a controller reference
* [`fs`](#fish-signal) - Creates a public RemoteSignal
* [`fp`](#fish-property) - Creates a public RemoteProperty
* [`fmf`](#fish-mapping-function) - Maps a function in a service
* [`fmp`](#fish-mapping-property) - Maps a property in a service
* [`fms`](#fish-mapping-signal) - Maps a signal in a service

### fish server
Initializes a service
<details>
<summary>Definition</summary>

```json
"fish server": {
	"prefix": "fishserver",
	"body": [
		"-- Services",
		"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
		"",
		"-- Core",
		"local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server",
		"local t = require(ReplicatedStorage.Packages.t)",
		"local $TM_FILENAME_BASE = {Client = {Signal = {}}}",
		"",
		"-- Dependencies",
		"local Promise = require(ReplicatedStorage.Packages.Promise)",
		"",
		"-- Functions",
		"function $TM_FILENAME_BASE.Start(self: self)",
		"\t$0",
		"end",
		"",
		"-- Mapping",
		"export type client = {",
		"\t",
		"}",
		"",
		"type self = typeof($TM_FILENAME_BASE)",
		"type sclient = typeof($TM_FILENAME_BASE.Client)",
		"type sclientsignal = typeof($TM_FILENAME_BASE.Client.Signal)",
		"return fish.service(\"$TM_FILENAME_BASE\", $TM_FILENAME_BASE, script)"
	],
	"description": "Template for fish framework server"
}
```
</details>
<details>
<summary>Output</summary>

```lua
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local t = require(ReplicatedStorage.Packages.t)
local MyService = {Client = {Signal = {}}}

-- Dependencies
local Promise = require(ReplicatedStorage.Packages.Promise)

-- Functions
function MyService.Start(self: self)
	
end

-- Mapping
export type client = {
	
}

type self = typeof(MyService)
type sclient = typeof(MyService.Client)
type sclientsignal = typeof(MyService.Client.Signal)
return fish.service("MyService", MyService, script)
```
</details>

---------------------------------

### fish client
Initializes a controller
<details>
<summary>Definition</summary>

```json
"fish client": {
	"prefix": "fishclient",
	"body": [
		"-- Services",
		"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
		"local ServerStorage = game:GetService(\"ServerStorage\")",
		"",
		"-- Core",
		"local fish = require(ReplicatedStorage.Packages.fish).Client",
		"local $TM_FILENAME_BASE = {}",
		"",
		"-- Functions",
		"function $TM_FILENAME_BASE.Start(self: self)",
		"\t$0",
		"end",
		"",
		"type self = & typeof($TM_FILENAME_BASE)",
		"return fish.controller(\"$TM_FILENAME_BASE\", $TM_FILENAME_BASE, script)"
	],
	"description": "Template for fish framework client"
}
```
</details>
<details>
<summary>Output</summary>

```lua
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Core
local fish = require(ReplicatedStorage.Packages.fish).Client
local MyController = {}

-- Functions
function MyController.Start(self: self)
	
end

type self = typeof(MyController)
return fish.controller("MyController", MyController, script)
```
</details>

---------------------------------

### fish function
Creates a public function
<details>
<summary>Definition</summary>

```json
"fish function": {
	"prefix": "ff",
	"body": [
		"function $TM_FILENAME_BASE.$1(self: self$2)",
		"\t$0",
		"end"
	],
	"description": "Snippet to create a public function"
}
```
</details>
<details>
<summary>Output</summary>

```lua
function MyService.Function(self: self)
	
end
```
</details>

---------------------------------

### fish function client
Create a public client function for a service
<details>
<summary>Definition</summary>

```json
"fish function client": {
	"prefix": "ffc",
	"body": [
		"function $TM_FILENAME_BASE.Client.$1(self: fish.self<sclient, self>$2)",
		"\t$0",
		"end"
	],
	"description": "Snippet to create a public client function for a service"
}
```
</details>
<details>
<summary>Output</summary>

```lua
function MyService.Client.Function(self: fish.self<sclient, self>)
	
end
```
</details>

---------------------------------

### fish function client signal
Create a public client function signal for a service
<details>
<summary>Definition</summary>

```json
"fish function client signal": {
	"prefix": "ffcs",
	"body": [
		"function $TM_FILENAME_BASE.Client.Signal.$1(self: fish.self<sclientsignal, self>$2)",
		"\t$0",
		"end",
	],
	"description": "Snippet to create a public client function signal for a service"
}
```
</details>
<details>
<summary>Output</summary>

```lua
function MyService.Client.Signal.Function(self: fish.self<sclientsignal, self>)
	
end
```
</details>

---------------------------------

### fish service reference server
Creates a service reference for the server
<details>
<summary>Definition</summary>

```json
"fish service reference server": {
	"prefix": "fss",
	"body": [
		"local $1 = require(script.Parent.$1)"
	],
	"description": "Snippet to create a service reference for the server"
}
```
</details>
<details>
<summary>Output</summary>

```lua
local OtherService = require(script.Parent.OtherService)
```
</details>

---------------------------------

### fish service reference client
Creates a service reference for the client
<details>
<summary>Definition</summary>

```json
"fish service reference client": {
	"prefix": "fsc",
	"body": [
		"local $1 = require(ServerStorage.Server.Services.$1); local $1: $1.client = $1"
	],
	"description": "Snippet to create a service reference for the client"
}
```
</details>
<details>
<summary>Output</summary>

```lua
local OtherService = require(ServerStorage.Server.Services.OtherService); local OtherService: OtherService.client = OtherService
```
</details>

---------------------------------

### fish controller reference
Creates a controller reference
<details>
<summary>Definition</summary>

```json
"fish controller reference": {
	"prefix": "fc",
	"body": [
		"local $1 = require(script.Parent.$1)"
	],
	"description": "Snippet to create a controller reference"
}
```
</details>
<details>
<summary>Output</summary>

```lua
local OtherController = require(script.Parent.OtherController)
```
</details>

---------------------------------

### fish signal
Creates a public RemoteSignal
<details>
<summary>Definition</summary>

```json
"fish signal": {
	"prefix": "fs",
	"body": [
		"$TM_FILENAME_BASE.Client.$1 = fish.signal()"
	],
	"description": "Snippet to create a public RemoteSignal"
}
```
</details>
<details>
<summary>Output</summary>

```lua
MyService.Client.Signal = fish.signal()
```
</details>

---------------------------------

### fish property
Creates a public RemoteProperty
<details>
<summary>Definition</summary>

```json
"fish property": {
	"prefix": "fp",
	"body": [
		"$TM_FILENAME_BASE.Client.$1 = fish.property()"
	],
	"description": "Snippet to create a public RemoteProperty"
}
```
</details>
<details>
<summary>Output</summary>

```lua
MyService.Client.Property = fish.property()
```
</details>

---------------------------------

### fish mapping function
Maps a function in a service
<details>
<summary>Definition</summary>

```json
"fish mapping function": {
	"prefix": "fmf",
	"body": [
		"$1: (self: any$2) -> Promise.TypedPromise<$3>$0"
	],
	"description": "Snippet to map a function in a service"
}
```
</details>
<details>
<summary>Output</summary>

```lua
Function: (self: any) -> Promise.TypedPromise<>
```
</details>

---------------------------------

### fish mapping property
Maps a property in a service
<details>
<summary>Definition</summary>

```json
"fish mapping property": {
	"prefix": "fmp",
	"body": [
		"$1: fish.ClientRemoteProperty$0"
	],
	"description": "Snippet to map a property in a service"
}
```
</details>
<details>
<summary>Output</summary>

```lua
Property: fish.ClientRemoteProperty
```
</details>

---------------------------------

### fish mapping signal
Maps a signal in a service
<details>
<summary>Definition</summary>

```json
"fish mapping signal": {
	"prefix": "fms",
	"body": [
		"$1: fish.ClientRemoteSignal$0"
	],
	"description": "Snippet to map a signal in a service"
}
```
</details>
<details>
<summary>Output</summary>

```lua
Signal: fish.ClientRemoteSignal
```
</details>

---------------------------------

### All snippets
All snippets in one
<details>
<summary>Definition</summary>

```json
{
	"fish server": {
		"prefix": "fishserver",
		"body": [
			"-- Services",
			"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
			"",
			"-- Core",
			"local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server",
			"local t = require(ReplicatedStorage.Packages.t)",
			"local $TM_FILENAME_BASE = {Client = {Signal = {}}}",
			"",
			"-- Dependencies",
			"local Promise = require(ReplicatedStorage.Packages.Promise)",
			"",
			"-- Functions",
			"function $TM_FILENAME_BASE.Start(self: self)",
			"\t$0",
			"end",
			"",
			"-- Mapping",
			"export type client = {",
			"\t",
			"}",
			"",
			"type self = typeof($TM_FILENAME_BASE)",
			"type sclient = typeof($TM_FILENAME_BASE.Client)",
			"type sclientsignal = typeof($TM_FILENAME_BASE.Client.Signal)",
			"return fish.service(\"$TM_FILENAME_BASE\", $TM_FILENAME_BASE, script)"
		],
		"description": "Template for fish framework server"
	},
	"fish client": {
		"prefix": "fishclient",
		"body": [
			"-- Services",
			"local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
			"local ServerStorage = game:GetService(\"ServerStorage\")",
			"",
			"-- Core",
			"local fish = require(ReplicatedStorage.Packages.fish).Client",
			"local $TM_FILENAME_BASE = {}",
			"",
			"-- Functions",
			"function $TM_FILENAME_BASE.Start(self: self)",
			"\t$0",
			"end",
			"",
			"type self = typeof($TM_FILENAME_BASE)",
			"return fish.controller(\"$TM_FILENAME_BASE\", $TM_FILENAME_BASE, script)"
		],
		"description": "Template for fish framework client"
	},
	"fish function": {
		"prefix": "ff",
		"body": [
			"function $TM_FILENAME_BASE.$1(self: self$2)",
			"\t$0",
			"end"
		],
		"description": "Snippet to create a public function"
	},
	"fish function client": {
		"prefix": "ffc",
		"body": [
			"function $TM_FILENAME_BASE.Client.$1(self: fish.self<sclient, self>$2)",
			"\t$0",
			"end"
		],
		"description": "Snippet to create a public client function for a service"
	},
	"fish function client signal": {
		"prefix": "ffcs",
		"body": [
			"function $TM_FILENAME_BASE.Client.Signal.$1(self: fish.self<sclientsignal, self>$2)",
			"\t$0",
			"end",
		],
		"description": "Snippet to create a public client function signal for a service"
	},
	"fish service reference server": {
		"prefix": "fss",
		"body": [
			"local $1 = require(script.Parent.$1)"
		],
		"description": "Snippet to create a service reference for the server"
	},
	"fish service reference client": {
		"prefix": "fsc",
		"body": [
			"local $1 = require(ServerStorage.Server.Services.$1); local $1: $1.client = $1"
		],
		"description": "Snippet to create a service reference for the client"
	},
	"fish controller reference": {
		"prefix": "fc",
		"body": [
			"local $1 = require(script.Parent.$1)"
		],
		"description": "Snippet to create a controller reference"
	},
	"fish signal": {
		"prefix": "fs",
		"body": [
			"$TM_FILENAME_BASE.Client.$1 = fish.signal()"
		],
		"description": "Snippet to create a public RemoteSignal"
	},
	"fish property": {
		"prefix": "fp",
		"body": [
			"$TM_FILENAME_BASE.Client.$1 = fish.property()"
		],
		"description": "Snippet to create a public RemoteProperty"
	},
	"fish mapping function": {
		"prefix": "fmf",
		"body": [
			"$1: (self: any$2) -> Promise.TypedPromise<$3>$0"
		],
		"description": "Snippet to map a function in a service"
	},
	"fish mapping property": {
		"prefix": "fmp",
		"body": [
			"$1: fish.ClientRemoteProperty$0"
		],
		"description": "Snippet to map a property in a service"
	},
	"fish mapping signal": {
		"prefix": "fms",
		"body": [
			"$1: fish.ClientRemoteSignal$0"
		],
		"description": "Snippet to map a signal in a service"
	}
}
```
</details>