---
title: Services
sidebar_position: 3
---

## Creating a Service
A service is a server module to handle an aspect of your game. To create a service *with full type support*, all you need is a few things.
First, import the fish module and access the server section and create a table with a Client table to represent your service. Optionally, add a Signal table within the Client table to help with creating signals in the future.
If you are wondering why you have to format the fish import like shown below, [read this](faq#why-is-fish-serverclient-imported-like-that) to understand.
```luau
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server
const MyService = {Client = {Signal = {}}}
```
:::caution
If there is no Client table or nothing is put inside of that table, the service will not be known to the client and any reference to it from the client will result in a runtime error. This can be intentionally used to hide service names if it benefits you.
:::
:::warning
Service modules should always be stored somewhere the client can't see, such as `ServerStorage`. If a service module is exposed to the client (e.g. stored in `ReplicatedStorage`), its source code could be read and a warning will be outputted on the client.
:::

Next, create a start function as apart of the service table. This will be ran once the framework is started. Define it with dot notation and pass in the `self` type to allow full autocomplete. (*this type is defined in the next code block*)
```luau
function MyService.Start(self: self)
	print("MyService has been started!")
end
```
Finally, you'll want to define some types to represent the service and then return the service by defining it with fish. The name of the service will be the name of the script.

#### **Final Result**
```luau
const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server
const MyService = {Client = {Signal = {}}}

function MyService.Start(self: self)
	print("MyService has been started!")
end

type self = typeof(MyService)
type client = typeof(MyService.Client)
type clientSignal = typeof(MyService.Client.Signal)
export type reference = fish.ServiceToReference<client>
return fish.service(script, MyService)
```
:::tip Snippet
**[fishserver](snippets/#fish-server) (fish server)**<br/>Initializes a service
:::
### Load Priority
**Services are loaded in an arbitrary order unless otherwise specified**. Ensure when referencing other services, that it can run safely if it doesn't start at the same time. Using any public functions should be safe, assuming that any logic done inside these functions don't depend on its Start function running first. It's also convention to run most code in the Start function and *not* outside in the global context.

To specify a load order, add the `LoadPriority` property to the service table. The service with the highest number will start first, then the next number under that and so on.
```luau
const MyService = {Client = {Signal = {}}, LoadPriority = 10}
```

:::note
If multiple services have the same load priority, those services will be started in an arbitrary order between themselves. If any services don't define their load priority, then they will start last after all the services with a defined load priority *(in an arbitrary order amongst themselves)*.

**Example**
* MyService `(LoadPriority: 10)` starts first
* DataService `(LoadPriority: 5)` and ShopService `(LoadPriority: 5)` start second and third in an arbitrary order
* PlayerService and MapService `(no LoadPriority)` start last in an arbitrary order
:::

Each Start function runs on its own thread. If a Start function yields, the next service will still start without waiting for it. If a Start function errors, the other services will still start.

## Public functions
You can create a function that is accessible by other services by defining a function in the service table. After all, a service is just a table.
```luau
-- MyService.lua
function MyService.PublicHello(self: self)
	print("Hello!")
end

-- OtherService.lua
const MyService = require("./MyService")

function OtherService.Start(self: self)
	MyService:PublicHello()
end
```
:::tip Snippet
**[ff](snippets/#fish-function) (fish function)**<br/>Creates a public function

**[fss](snippets/#fish-service-reference-server) (fish service reference server)**<br/>Creates a service reference for the server
:::

## Public signals
You can also import the [Signal](https://sleitnick.github.io/RbxUtil/api/Signal/) package and define it in the service table, allowing you to send events to other services.
```luau
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

## Reference
The reference is the type of what is available to the client. This is crucial in order for the client to know about what services expose to them. Instead of writing this type yourself, fish creates it for you using `fish.ServiceToReference` with the type of your Client table.
```luau
type client = typeof(MyService.Client)
export type reference = fish.ServiceToReference<client>
```
Everything in the Client table gets converted into what the client sees:
* [Client functions](#adding-client-functions-to-a-service) are converted to return a [Promise](https://eryn.io/roblox-lua-promise/api/Promise) that is resolved once the server returns a value.
* [Signals](#signals) and [properties](#properties) are converted to their client version.
* Functions in the [Signal table](#signals) are converted to signals.
* Anything else is not included.

```luau
function MyService.Client.GetMoney(self: fish.self<client, self>): number
	return 100
end
-- In the reference:
--> GetMoney: (self: any) -> Promise.TypedPromise<number>

MyService.Client.Announcement = fish.signal()
-- In the reference:
--> Announcement: ClientRemoteSignal
```
:::caution
Client functions can only have their return values typed up to a maximum of **9 return values**. If a client function returns more than 9 values, the Promise it returns will no longer be typed.
:::

## Adding client functions to a Service
All functions added to the Client table are automatically exposed to the client and can be called. The [reference](#reference) will automatically include these functions.

fish provides its own self object that contains the player who called the function, useful libraries like [Mutex](advanced-features/mutex) that is exclusive for each function, as well as being able to access any public client function or server function. See all entries in the [API](/api/Types#self<C,S>). Provide the types of your own client table and service table as parameters to fish.self for full type completion as well.
```luau
function MyService.Client.SayHello(self: fish.self<client, self>)
	print("Hello from " .. self.Player.Name)
	-- self.Mutex is available
	-- self.confirm is available
	-- Any other client functions can be called using self:OtherClientFunction()
	-- Any server functions in this service can be called using self.Server:SomeServerFunction()
end
```
:::tip Snippet
**[ffc](snippets/#fish-function-client) (fish function client)**<br/>Create a public client function for a service
:::
Here's another example of a client function with parameters, type checking, and return values. This uses the [t package](https://github.com/osyrisrblx/t#readme) to validate types, making it very easy and concise to ensure the values passed in by the client is what you're expecting.
```luau
function MyService.Client.GetInstanceProperty(self: fish.self<client, self>, instance: Instance, propertyName: string?): any
	assert(t.tuple(t.Instance, t.optional(t.string))(instance, propertyName))

	if propertyName == nil then
		return instance.Name
	else
		return instance[propertyName]
	end
end
```

## Client Communication
Communicating with the client is only possible using **one-way communication** (**server -> client** or **client -> server**) through firing data to a set of players using one of the following methods:
* [Signals](#signals), which is a **one-time event** where data is sent from one side of the network and received on the other. Either side of the network can connect to a signal to listen for when an event gets fired to it and read the data attached. An event gets fired once and does not get repeated.
* [Properties](#properties), which is a way of sharing data that can be read from or have its changes observed **at any point in time**. This data can be set to be the same for everyone, or can be modified independently for a single player. An example could be a server timer value that everyone sees the same, or a money value which each player sees their own data instead of a shared common value.

### Signals
[Signals](https://sleitnick.github.io/RbxUtil/api/RemoteSignal/) (see their API for more info) allow you to send data to any player which are able to be listened to on the client in any controller. Signals can also be listened to on the server, allowing the client to fire an event and send data to the server without expecting a response. To create a signal, you want to use `fish.signal()` and define it in the Client table of the service to expose it.
```luau
MyService.Client.MoneyUpdated = fish.signal()
```
:::tip Snippet
**[fs](snippets/#fish-signal) (fish signal)**<br/>Creates a public RemoteSignal
:::
:::note
Signals are not created until `fish.start()` is called as this function only creates a marker to indicate to the framework that a signal is wanted to be created. When a service's `Start()` function is called, it is safe to start using the signal.
:::
Here's an example of how to fire to a client and for a controller to listen to this signal.
```luau
-- MyService.lua
function MyService.AddMoney(self: self, player: Player, amount: number)
	money[player] += amount
	self.Client.MoneyUpdated:Fire(player, money[player])
end

-- MyController.lua
function MyController.Start(self: self)
	MyService.MoneyUpdated:Connect(function(money)
		print("I have $" .. money .. " now!")
	end)
end
```
If you wish to listen to when the client fires an event to the server, you can either listen to the same way `MyController.Start()` does in the code block above but on the server instead, or you can use the Signal table defined earlier within the Client table. This convention follows very similarly to [client functions](#adding-client-functions-to-a-service) and is therefore recommended.
```luau
-- MyService.lua
function MyService.Client.Signal.MousePositionUpdate(self: fish.self<clientSignal, self>, position: Vector2)
	print("The mouse position of " .. self.Player.Name .. " is now " .. tostring(position))
end

-- MyController.lua
const Mouse = Players.LocalPlayer:GetMouse()
function MyController.Start(self: self)
	local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
	MyService.MousePositionUpdate:Fire(mousePosition)
end
```
:::tip Snippet
**[ffcs](snippets/#fish-function-client-signal) (fish function client signal)**<br/>Create a public client function signal for a service
:::

### Properties
[Properties](https://sleitnick.github.io/RbxUtil/api/RemoteProperty) (see their API for more info) allow you to share any type of data with all players and additionally modify that data only for a specific player. For example, this is a good way to store a currency as you can set the default value to 0 in the property, but later modify that value for a player to match what they have allowing the client to listen to when that value changes with `Observe()` or to get it at any point in time using `Get()`. To create a property, you want to use `fish.property()` and define it in the Client table of the service to expose it.
```luau
MyService.Client.Money = fish.property(0) -- pass in the initial value of the property
```
:::tip Snippet
**[fp](snippets/#fish-property) (fish property)**<br/>Creates a public RemoteProperty
:::
:::note
Properties are not created until `fish.start()` is called as this function only creates a marker to indicate to the framework that a property is wanted to be created. When a service's `Start()` function is called, it is safe to start using the property.
:::
Here's an example of how to use a property and for a controller to read this property.
```luau
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
```luau
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const fish = require(ReplicatedStorage.Packages.fish); const fish = fish.Server
const Signal = require(ReplicatedStorage.Packages.Signal)
const t = require(ReplicatedStorage.Packages.t)
const PlayerService = {Client = {Signal = {}}}

PlayerService.OnMoneyChange = Signal.new()

PlayerService.Client.Announcement = fish.signal()
PlayerService.Client.Money = fish.property(0)

function PlayerService.AddMoney(self: self, player: Player, amount: number)
	const currentMoney = self.Client.Money:GetFor(player)
	self.Client.Money:SetFor(player, currentMoney + amount)
	self.OnMoneyChange:Fire(player, currentMoney + amount)
end

function PlayerService.Client.AskForMoney(self: fish.self<client, self>, amount: number): boolean
	self.confirm(t.number(amount)) -- equivalent to assert(), but silently fails instead of throwing an error
	if math.random() < 0.1 then
		self.Server:AddMoney(self.Player, amount)
		print(self.Player.Name .. " now has $" .. self.Money:GetFor(self.Player))
		return true
	else
		return false
	end
end

function PlayerService.Client.Signal.SendChat(self: fish.self<clientSignal, self>, message: string)
	self.confirm(t.string(message))
	self.Server.Client.Announcement:FireAll(self.Player.Name .. ": " .. message)
end

function PlayerService.Start(self: self)
	Players.PlayerAdded:Connect(function(player)
		self.Client.Money:SetFor(player, 10)
		self.Client.Announcement:FireAll(player.Name .. " has joined the game!")
	end)
end

type self = typeof(PlayerService)
type client = typeof(PlayerService.Client)
type clientSignal = typeof(PlayerService.Client.Signal)
export type reference = fish.ServiceToReference<client>
return fish.service(script, PlayerService)
```
