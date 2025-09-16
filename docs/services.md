---
title: Services
sidebar_position: 3
---

## Creating a Service
A service is a server module to handle an aspect of your game. To create a service *with full type support*, all you need is a few things.
First, import the fish module and access the server section and create a table with a Client table to represent your service. Optionally, add a Signal table within the Client table to help with creating signals in the future.
If you are wondering why you have to format the fish import like shown below, [read this](faq#why-is-fish-server-imported-like-that) to understand.
```lua
local fish = require(ReplicatedStorage.Packages.fish); local fish = fish.Server
local MyService = {Client = {Signal = {}}}
```
:::caution
If there is no Client table or nothing is put inside of that table, the service will not be known to the client and any reference to it from the client will result in a runtime error. This can be intentionally used to hide service names if it benefits you.
:::

Next, create a start function as apart of the service table. This will be ran once the framework is started. Define it with dot notation and pass in the `self` type to allow full autocomplete. (*this type is defined in the next code block*)
```lua
function MyService.Start(self: self)
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

function MyService.Start(self: self)
	print("MyService has been started!")
end

-- Mapping
export type client = {}

type self = server
type server = typeof(MyService)
type sclient = typeof(MyService.Client)
type sclientsignal = typeof(MyService.Client.Signal)
return fish.service("MyService", MyService, script)
```
:::tip Snippet
**[fishserver](snippets/#fish-server) (fish server)**<br/>Initializes a service
:::
## Public functions
You can create a function that is accessible by other services by defining a function in the service table. After all, a service is just a table.
```lua
-- MyService.lua
function MyService.PublicHello(self: self)
	print("Hello!")
end

-- OtherService.lua
function OtherService.Start(self: self)
	MyService:PublicHello()
end
```
:::tip Snippet
**[ff](snippets/#fish-function) (fish function)**<br/>Creates a public function
:::

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
function OtherService.Start(self: self)
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
:::tip Snippet
**[fmf](snippets/#fish-mapping-function) (fish mapping function)**<br/>Maps a function in a service
:::


### Client Signals/Properties
Simply use the appropriate type of `fish.ClientRemoteSignal` or `fish.ClientRemoteProperty` when defining signals or properties.
```lua
export type client = {
	SomeSignal: fish.ClientRemoteSignal,
	SomeProperty: fish.ClientRemoteProperty
}
```
:::tip Snippet
**[fms](snippets/#fish-mapping-signal) (fish mapping signal)**<br/>Maps a signal in a service

**[fmp](snippets/#fish-mapping-property) (fish mapping property)**<br/>Maps a property in a service
:::

## Adding client functions to a Service
All functions added to the Client table are automatically exposed to the client and can be called. In order for proper typing, you must also define a [mapping](#mapping) that returns a Promise.

fish provides its own self object that contains the player who called the function, useful libraries like [Mutex](https://en.wikipedia.org/wiki/Mutual_exclusion) that is exclusive for each function, as well as being able to access any public client function or server function. See all entries in the [API](/api/Types#self<C,S>). Provide the types of your own client table and service table as parameters to fish.self for full type completion as well.
```lua
function MyService.Client.SayHello(self: fish.self<sclient, server>)
	print("Hello from " .. self.Player)
	-- self.Mutex is available
	-- self.confirm is available
	-- Any other client functions can be called using self:OtherClientFunction()
	-- Any server functions in this server can be called using self.Server:SomeServerFunction()
end

-- Mapping
export type client = {
	SayHello: (self: any) -> Promise.TypedPromise<>
}
```
:::tip Snippet
**[ffc](snippets/#fish-function-client) (fish function client)**<br/>Create a public client function for a service
:::
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
Communicating with the client is only possible using **one-way communication** (**server -> client** or **client -> server**) through firing data to a set of players using one of the following methods:
* [Signals](#signals), which is a **one-time event** where data is sent from one side of the network and received on the other. Either side of the network can connect to a signal to listen for when an event gets fired to it and read the data attached. An event gets fired once and does not get repeated.
* [Properties](#properties), which is a way of sharing data that can be read from or have its changes observed **at any point in time**. This data can be set to be the same for everyone, or can be modified independently for a single player. An example could be a server timer value that everyone sees the same, or a money value which each player sees their own data instead of a shared common value.

### Signals
[Signals](https://sleitnick.github.io/RbxUtil/api/RemoteSignal/) (see their API for more info) allow you to send data to any player which are able to be listened to on the client in any controller. Signals can also be listened to on the server, allowing the client to fire an event and send data to the server without expecting a response. To create a signal, you want to use `fish.signal()` and define it in the Client table of the service to expose it. **You will also need to map this** which is shown below.
```lua
MyService.Client.MoneyUpdated = fish.signal()

export type client = {
	MoneyUpdated: fish.ClientRemoteSignal
}
```
:::tip Snippet
**[fs](snippets/#fish-signal) (fish signal)**<br/>Creates a public RemoteSignal
:::
:::note
Signals are not created until `fish.start()` is called as this function only creates a marker to indicate to the framework that a signal is wanted to be created. When a service's `Start()` function is called, it is safe to start using the signal.
:::
Here's an example of how to fire to a client and for a controller to listen to this signal.
```lua
-- MyService.lua
function MyService.AddMoney(self: self, player: Player, amount: number)
	money[player] -= amount
	self.Client.MoneyUpdated:FireFor(player, amount)
end

-- MyController.lua
function MyController.Start(self: self)
	MyService.MoneyUpdated:Connect(function(money)
		print("I have $" .. money .. " now!")
	end)
end
```
If you wish to listen to when the client fires an event to the server, you can either listen to the same way `MyController.Start()` does in the code block above but on the server instead, or you can use the Signal table defined earlier within the Client table. This convention follows very similarly to [client functions](#adding-client-functions-to-a-service) and is therefore recommended.
```lua
-- MyService.lua
function MyService.Client.Signal.MousePositionUpdate(self: fish.self<sclientsignal, server>, position: Vector2)
	print("The mouse position of " .. player.Name .. " is now " .. tostring(position))
end

export type client = {
	MousePositionUpdate: fish.ClientRemoteSignal
}

-- MyController.lua
local Mouse = Players.LocalPlayer:GetMouse()
function MyController.Start(self: self)
	local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
	MyService.MousePositionUpdate:Fire(mousePosition)
end
```
:::tip Snippet
**[ffcs](snippets/#fish-function-client-signal) (fish function client signal)**<br/>Create a public client function signal for a service
:::

### Properties
[Properties](https://sleitnick.github.io/RbxUtil/api/RemoteProperty) (see their API for more info) allow you to share any type of data with all players and additionally modify that data only for a specific player. For example, this is a good way to store a currency as you can set the default value to 0 in the property, but later modify that value for a player to match what they have allowing the client to listen to when that value changes with `Observe()` or to get it at any point in time using `Get()`. To create a property, you want to use `fish.property()` and define it in the Client table of the service to expose it. **You will also need to map this** which is shown below.
```lua
MyService.Client.Money = fish.property(0) -- pass in the initial value of the property

export type client = {
	Money: fish.ClientRemoteProperty
}
```
:::tip Snippet
**[fp](snippets/#fish-property) (fish property)**<br/>Creates a public RemoteProperty
:::
:::note
Properties are not created until `fish.start()` is called as this function only creates a marker to indicate to the framework that a property is wanted to be created. When a service's `Start()` function is called, it is safe to start using the property.
:::
Here's an example of how to use a property and for a controller to read this property.
```lua
-- MyService.lua
function MyService.AddMoney(self: self, player: Player, amount: number)
	local currentMoney: number = self.Client.Money:GetFor(player)
	self.Client.Money:SetFor(player, currentMoney + amount)
end

-- MyController.lua
function MyController.Start(self: self)
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

function PlayerService.AddMoney(self: self, player: Player, amount: number)
	local currentMoney = self.Client.Money:GetFor(player)
	self.Client.Money:SetFor(money, currentMoney + amount)
	self.OnMoneyChange:FireAll(player, currentMoney + amount)
end

function PlayerService.Client.AskForMoney(self: fish.self<sclient, server>, amount: number): boolean
	self.confirm(t.number(amount)) -- equivalent to assert(), but silently fails instead of throwing an error
	if math.random() < 0.1 then
		self.Server:AddMoney(self.Player, amount)
		print(self.Player.Name .. " now has $" .. self.Money:GetFor(self.Player))
		return true
	else
		return false
	end
end

function PlayerService.Start(self: self)
	Players.PlayerAdded:Connect(function(player)
		self.Client.Money:SetFor(player, 10)
		self.Client.Announcement:FireAll(player.Name .. " has joined the game!")
	end)
end

-- Mapping
export type client = {
	AskForMoney: (self: any, amount: number) -> Promise.TypedPromise<boolean>,

	Announcement: fish.ClientRemoteSignal,
	Money: fish.ClientRemoteProperty
}

type self = server
type server = typeof(PlayerService)
type sclient = typeof(PlayerService.Client)
type sclientsignal = typeof(PlayerService.Client.Signal)
return fish.service("PlayerService", PlayerService, script)
```