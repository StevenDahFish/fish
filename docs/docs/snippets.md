---
title: Snippets
sidebar_position: 7
---

These snippets can help speed up workflow by allowing you to easily define entire services/controllers or components of these and focus on writing code! These are written for [VSCode](https://code.visualstudio.com/) and are usable in `File > Preferences > Configure Snippets > luau.json`.

### Cheat Sheet
* [`fishserver`](#fish-server) - Initializes a service
* [`fishclient`](#fish-client) - Initializes a controller
* [`ff`](#fish-function) - Creates a public function
* [`ffs`](#fish-function-self) - Creates a function that explicitly defines the type of self
* [`ffc`](#fish-function-client) - Create a public client function for a service
* [`ffcs`](#fish-function-client-signal) - Create a public client function signal for a service
* [`fss`](#fish-service-reference-server) - Creates a service reference for the server
* [`fsc`](#fish-service-reference-client) - Creates a service reference for the client
* [`fc`](#fish-controller-reference) - Creates a controller reference
* [`fs`](#fish-signal) - Creates a public RemoteSignal
* [`fp`](#fish-property) - Creates a public RemoteProperty

### fish server
Initializes a service
<details>
<summary>Definition</summary>

```json
"fish server": {
	"prefix": "fishserver",
	"body": [
		"-- Services",
		"const ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
		"",
		"-- Core",
		"const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server",
		"const t = require(ReplicatedStorage.Packages.t)",
		"const $TM_FILENAME_BASE = {Client = {Signal = {}}}",
		"",
		"-- Functions",
		"function $TM_FILENAME_BASE.Start(self: self)",
		"\t$0",
		"end",
		"",
		"type self = typeof($TM_FILENAME_BASE)",
		"type client = typeof($TM_FILENAME_BASE.Client)",
		"type clientSignal = typeof($TM_FILENAME_BASE.Client.Signal)",
		"export type reference = fish.ServiceToReference<client>",
		"return fish.service(script, $TM_FILENAME_BASE)"
	],
	"description": "Template for fish framework server"
}
```
</details>
<details>
<summary>Output</summary>

```luau
-- Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server
const t = require(ReplicatedStorage.Packages.t)
const MyService = {Client = {Signal = {}}}

-- Functions
function MyService.Start(self: self)
	
end

type self = typeof(MyService)
type client = typeof(MyService.Client)
type clientSignal = typeof(MyService.Client.Signal)
export type reference = fish.ServiceToReference<client>
return fish.service(script, MyService)
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
		"const ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
		"",
		"-- Core",
		"const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client",
		"const $TM_FILENAME_BASE = {}",
		"",
		"-- Functions",
		"function $TM_FILENAME_BASE.Start(self: self)",
		"\t$0",
		"end",
		"",
		"type self = typeof($TM_FILENAME_BASE)",
		"return fish.controller(script, $TM_FILENAME_BASE)"
	],
	"description": "Template for fish framework client"
}
```
</details>
<details>
<summary>Output</summary>

```luau
-- Services
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Core
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client
const MyController = {}

-- Functions
function MyController.Start(self: self)
	
end

type self = typeof(MyController)
return fish.controller(script, MyController)
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
		"function $TM_FILENAME_BASE.${1}(self: self$2)",
		"\t$0",
		"end"
	],
	"description": "Snippet to create a public function"
}
```
</details>
<details>
<summary>Output</summary>

```luau
function MyService.Function(self: self)
	
end
```
</details>

---------------------------------

### fish function self
Creates a function that explicitly defines the type of self
<details>
<summary>Definition</summary>

```json
"fish function self": {
	"prefix": "ffs",
	"body": [
		"function $TM_FILENAME_BASE.${1}(self: $TM_FILENAME_BASE)",
		"\t$0",
		"end"
	],
	"description": "Snippet to create a function that explicitly defines the type of self"
}
```
</details>
<details>
<summary>Output</summary>

```luau
function MyService.Function(self: MyService)
	
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
		"function $TM_FILENAME_BASE.Client.${1}(self: fish.self<client, self>${2})",
		"\t$0",
		"end"
	],
	"description": "Snippet to create a public client function for a service"
}
```
</details>
<details>
<summary>Output</summary>

```luau
function MyService.Client.Function(self: fish.self<client, self>)
	
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
		"function $TM_FILENAME_BASE.Client.Signal.${1}(self: fish.self<clientSignal, self>${2})",
		"\t$0",
		"end"
	],
	"description": "Snippet to create a public client function signal for a service"
}
```
</details>
<details>
<summary>Output</summary>

```luau
function MyService.Client.Signal.Function(self: fish.self<clientSignal, self>)
	
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
		"const ${1} = require(\"./${1}\")"
	],
	"description": "Snippet to create a service reference for the server"
}
```
</details>
<details>
<summary>Output</summary>

```luau
const OtherService = require("./OtherService")
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
		"const ${1} = require(\"@game/ServerStorage/Server/Services/${1}\"); const ${1} = (${1} :: unknown) :: ${1}.reference"
	],
	"description": "Snippet to create a service reference for the client"
}
```
</details>
<details>
<summary>Output</summary>

```luau
const OtherService = require("@game/ServerStorage/Server/Services/OtherService"); const OtherService = (OtherService :: unknown) :: OtherService.reference
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
		"const ${1} = require(\"./${1}\")"
	],
	"description": "Snippet to create a controller reference"
}
```
</details>
<details>
<summary>Output</summary>

```luau
const OtherController = require("./OtherController")
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
		"$TM_FILENAME_BASE.Client.${1} = fish.signal()"
	],
	"description": "Snippet to create a public RemoteSignal"
}
```
</details>
<details>
<summary>Output</summary>

```luau
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
		"$TM_FILENAME_BASE.Client.${1} = fish.property()"
	],
	"description": "Snippet to create a public RemoteProperty"
}
```
</details>
<details>
<summary>Output</summary>

```luau
MyService.Client.Property = fish.property()
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
			"const ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
			"",
			"-- Core",
			"const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server",
			"const t = require(ReplicatedStorage.Packages.t)",
			"const $TM_FILENAME_BASE = {Client = {Signal = {}}}",
			"",
			"-- Functions",
			"function $TM_FILENAME_BASE.Start(self: self)",
			"\t$0",
			"end",
			"",
			"type self = typeof($TM_FILENAME_BASE)",
			"type client = typeof($TM_FILENAME_BASE.Client)",
			"type clientSignal = typeof($TM_FILENAME_BASE.Client.Signal)",
			"export type reference = fish.ServiceToReference<client>",
			"return fish.service(script, $TM_FILENAME_BASE)"
		],
		"description": "Template for fish framework server"
	},
	"fish client": {
		"prefix": "fishclient",
		"body": [
			"-- Services",
			"const ReplicatedStorage = game:GetService(\"ReplicatedStorage\")",
			"",
			"-- Core",
			"const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Client",
			"const $TM_FILENAME_BASE = {}",
			"",
			"-- Functions",
			"function $TM_FILENAME_BASE.Start(self: self)",
			"\t$0",
			"end",
			"",
			"type self = typeof($TM_FILENAME_BASE)",
			"return fish.controller(script, $TM_FILENAME_BASE)"
		],
		"description": "Template for fish framework client"
	},
	"fish function": {
		"prefix": "ff",
		"body": [
			"function $TM_FILENAME_BASE.${1}(self: self$2)",
			"\t$0",
			"end"
		],
		"description": "Snippet to create a public function"
	},
	"fish function self": {
		"prefix": "ffs",
		"body": [
			"function $TM_FILENAME_BASE.${1}(self: $TM_FILENAME_BASE)",
			"\t$0",
			"end"
		],
		"description": "Snippet to create a function that explicitly defines the type of self"
	},
	"fish function client": {
		"prefix": "ffc",
		"body": [
			"function $TM_FILENAME_BASE.Client.${1}(self: fish.self<client, self>${2})",
			"\t$0",
			"end"
		],
		"description": "Snippet to create a public client function for a service"
	},
	"fish function client signal": {
		"prefix": "ffcs",
		"body": [
			"function $TM_FILENAME_BASE.Client.Signal.${1}(self: fish.self<clientSignal, self>${2})",
			"\t$0",
			"end"
		],
		"description": "Snippet to create a public client function signal for a service"
	},
	"fish service reference server": {
		"prefix": "fss",
		"body": [
			"const ${1} = require(\"./${1}\")"
		],
		"description": "Snippet to create a service reference for the server"
	},
	"fish service reference client": {
		"prefix": "fsc",
		"body": [
			"const ${1} = require(\"@game/ServerStorage/Server/Services/${1}\"); const ${1} = (${1} :: unknown) :: ${1}.reference"
		],
		"description": "Snippet to create a service reference for the client"
	},
	"fish controller reference": {
		"prefix": "fc",
		"body": [
			"const ${1} = require(\"./${1}\")"
		],
		"description": "Snippet to create a controller reference"
	},
	"fish signal": {
		"prefix": "fs",
		"body": [
			"$TM_FILENAME_BASE.Client.${1} = fish.signal()"
		],
		"description": "Snippet to create a public RemoteSignal"
	},
	"fish property": {
		"prefix": "fp",
		"body": [
			"$TM_FILENAME_BASE.Client.${1} = fish.property()"
		],
		"description": "Snippet to create a public RemoteProperty"
	}
}
```
</details>
