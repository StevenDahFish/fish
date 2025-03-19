---
title: Services
sidebar_position: 3
---

A service is a server module to handle an aspect of your game. To create a service *with full type support*, all you need is a few things.
First, import the fish module and access the server section and create a table with a Client table to represent your service.
If you are wondering why you have to format the fish import like shown below, [read this](faq#why-is-fish-server-imported-like-that) to understand.
```lua
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local MyService = {Client = {}}
```
:::caution
If there is no Client table or nothing is put inside of that table, the service will not be known to the client and any reference to it from the client will result in a runtime error. This can be intentionally used to hide service names if it benefits you.
:::

Next, create a start function as apart of the service table. This will be ran once the framework is started.
```lua
function MyService:Start()
	print("MyService has been started!")
end
```
:::note
**Services are loaded in an abitrary order**. Ensure when referencing other services, that it can run safely if it doesn't start at the same time. Using any public functions should be safe, assuming that any logic done inside these functions don't depend on its Start function running first. It's also convention to run most code in the Start function and *not* outside in the global context.
:::
Finally, you'll want to define some types for defining client functions later and then return the service by defining it with fish.

#### **Final Result**
```lua
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local MyService = {Client = {}}

function MyService:Start()
	print("MyService has been started!")
end

-- Mapping
export type client = {}

type server = typeof(MyService)
type sclient = typeof(MyService.Client)
return fish.service("MyService", MyService, script)
```
## Public functions
You can create a function that is accessible by other services by defining a function in the service table. After all, a service is just a table.
```lua
-- MyService.lua
function MyService:PublicHello()
	print("Hello!")
end

-- OtherService.lua
function OtherService:Start()
	MyService:PublicHello()
end
```

## Public signals
You can also import the [Signal](https://sleitnick.github.io/RbxUtil/api/Signal/) package and define it in the service table, allowing you to send events to other services.
```lua
-- MyService.lua
MyService.OnHello = Signal.new()

local function hello()
	print("Hello!")
	MyService.OnHello:Fire()
end

-- OtherService.lua
function OtherService:Start()
	MyService.OnHello:Connect(function()
		print("Received hello!")
	end)
end
```

## Mapping
Mapping is the act of typing what is available to the client. This is crucial in order for the client to know about what services expose to them. This means any client functions, signals, or properties you create, you must put it in the mapping in order for it to be recognized in controllers. If this service is planned to not have any public features, it is not necessary to create mappings.
```lua
export type client = {}
```
### Client Functions
All client functions return a [Promise](https://eryn.io/roblox-lua-promise/api/Promise) that is resolved once the server returns a value. You must account for this when writing the mapping. Additionally for convention, all functions should be seen as "methods" which means `self` should be passed in as the first argument with type `any`.
```lua
export type client = {
	GetMoney: (self: any) -> Promise.TypedPromise<number>,
	-- Represents:
	--> function MyService.Client.GetMoney(self: fish.self<sclient, server>): number

	SetMoney: (self: any, amount: number) -> Promise.TypedPromise<>
	-- Represents:
	--> function MyService.Client.SetMoney(self: fish.self<sclient, server>, amount: number)
}
```

### Client Signals/Properties
Simply use the appropriate type of `fish.ClientRemoteSignal` or `fish.ClientRemoteProperty` when defining signals or properties.
```lua
export type client = {
	SomeSignal: fish.ClientRemoteSignal,
	SomeProperty: fish.ClientRemoteProperty
}
```

## Adding client functions to a Service
All functions added to the Client table are automatically exposed to the client and can be called. In order for proper typing, you must also define a [mapping](#mapping) that returns a Promise.

fish provides its own self object that contains the player who called the function, useful libraries like [Mutex](https://en.wikipedia.org/wiki/Mutual_exclusion) that is exclusive for each function, as well as being able to access any public client function or server function. See all entries in the [API](/api/Types#self<C,S>). Provide the types of your own client table and service table as parameters to fish.self for full type completion as well.
```lua
function MyService.Client.SayHello(self: fish.self<sclient, server>)
	print("Hello from " .. self.Player)
	-- self.Mutex is available
	-- Any other client functions can be called using self:OtherClientFunction()
	-- Any server functions in this server can be called using self.Server:SomeServerFunction()
end

-- Mapping
export type client = {
	SayHello: (self: any) -> Promise.TypedPromise<>
}
```
Here's another example of a client function with parameters, type checking, and return values. This uses the [t package](https://github.com/osyrisrblx/t#readme) to validate types, making it very easy and concise to ensure the values passed in by the client is what you're expecting.
```lua
function MyService.Client.GetInstanceProperty(self: fish.self<sclient, server>, instance: Instance, propertyName: string?): any
	assert(t.tuple(t.Instance, t.optional(t.string))(instance, propertyName))

	if propertyName == nil then
		return instance.Name
	else
		return instance[propertyName]
	end
end

-- Mapping
export type client = {
	GetInstanceProperty: (self: any, instance: Instance, propertyName: string?) -> Promise.TypedPromise<any>
}
```

## Client Communication
Communicating with the client is only possible one-way through firing data to a set of players using signals or have a per-player shared value with properties.

### Signals
[Signals](https://sleitnick.github.io/RbxUtil/api/RemoteSignal/) (see their API for more info) allow you to send data to any player which are listenable on the client in any controller. To create a signal, you want to use `fish.signal()` and define it in the Client table of the service to expose it. **You will also need to map this** which is shown below.
```lua
MyService.Client.MoneyUpdated = fish.signal()

export type client = {
	MoneyUpdated: fish.ClientRemoteSignal
}
```
:::note
Signals are not created until `fish.start()` is called as this function only creates a marker to indicate to the framework that a signal is wanted to be created. When a service's `Start()` function is called, it is safe to start using the signal.
:::
Here's an example of how to fire to a client and for a controller to listen to this signal.
```lua
-- MyService.lua
function MyService:AddMoney(player: Player, amount: number)
	money[player] -= amount
	MyService.Client.MoneyUpdated:FireFor(player, amount)
end

-- MyController.lua
function MyController:Start()
	MyService.MoneyUpdated:Connect(function(money)
		print("I have $" .. money .. " now!")
	end)
end
```

### Properties
[Properties](https://sleitnick.github.io/RbxUtil/api/RemoteProperty) (see their API for more info) allow you to share any type of data with all players and additionally modify that data only for a specific player. For example, this is a good way to store a currency as you can set the default value to 0 in the property, but later modify that value for a player to match what they have allowing the client to listen to when that value changes with `Observe()` or to get it at any point in time using `Get()`. To create a property, you want to use `fish.property()` and define it in the Client table of the service to expose it. **You will also need to map this** which is shown below.
```lua
MyService.Client.Money = fish.property(0) -- pass in the initial value of the property

export type client = {
	Money: fish.ClientRemoteProperty
}
```
:::note
Properties are not created until `fish.start()` is called as this function only creates a marker to indicate to the framework that a property is wanted to be created. When a service's `Start()` function is called, it is safe to start using the property.
:::
Here's an example of how to use a property and for a controller to read this property.
```lua
-- MyService.lua
function MyService:AddMoney(player: Player, amount: number)
	local currentMoney: number = MyService.Client.Money:GetFor(player)
	MyService.Client.Money:SetFor(player, currentMoney + amount)
end

-- MyController.lua
function MyController:Start()
	-- Fires immediately with the current value, then fires every time money changes
	MyService.Money:Observe(function(money)
		print("I currently have $" .. money)	
	end)

	-- One-time get
	local currentMoney = MyService.Money:Get()
	print("At this moment, I have $" .. currentMoney)
end
```

## Full Example
<!-- See the [tests folder](https://github.com/StevenDahFish/fish/tree/master/tests) in the GitHub repository for a full game example. -->
```lua
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local t = require(ReplicatedStorage.Packages.t)
local PlayerService = {Client = {}}

PlayerService.OnMoneyChange = Signal.new()

PlayerService.Client.Announcement = fish.signal()
PlayerService.Client.Money = fish.property(0)

function PlayerService:AddMoney(player: Player, amount: number)
	local currentMoney = PlayerService.Client.Money:GetFor(player)
	PlayerService.Client.Money:SetFor(money, currentMoney + amount)
	PlayerService.OnMoneyChange:FireAll(player, currentMoney + amount)
end

function PlayerService.Client.AskForMoney(self: fish.self<sclient, server>, amount: number): boolean
	assert(t.number(amount))
	if math.random() < 0.1 then
		self.Server:AddMoney(self.Player, amount)
		print(self.Player.Name .. " now has $" .. self.Money:GetFor(self.Player))
		return true
	else
		return false
	end
end

function PlayerService:Start()
	Players.PlayerAdded:Connect(function(player)
		PlayerService.Client.Money:SetFor(player, 10)
		PlayerService.Client.Announcement:FireAll(player.Name .. " has joined the game!")
	end)
end

-- Mapping
export type client = {
	AskForMoney: (self: any, amount: number) -> Promise.TypedPromise<boolean>,

	Announcement: fish.ClientRemoteSignal,
	Money: fish.ClientRemoteProperty
}

type server = typeof(PlayerService)
type sclient = typeof(PlayerService.Client)
return fish.service("PlayerService", PlayerService, script)
```