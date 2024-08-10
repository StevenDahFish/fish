--[=[
	@ignore
	@class DependencyTypes
]=]

--[=[
	@ignore
	@prop N/A nil
	@within DependencyTypes
	Comm - sleitnick
	These types were already written -- this was put into this module for ease of access
]=]
export type Args = {
	n: number,
	[any]: any,
}

export type FnBind = (Instance, ...any) -> ...any

export type ServerMiddlewareFn = (Instance, Args) -> (boolean, ...any)
export type ServerMiddleware = { ServerMiddlewareFn }

export type ClientMiddlewareFn = (Args) -> (boolean, ...any)
export type ClientMiddleware = { ClientMiddlewareFn }

--[=[
	@ignore
	@prop N/A nil
	@within DependencyTypes
	RemoteSignal - sleitnick
]=]

--[=[
	@ignore
	@class RemoteSignal
	@server
	Created via `ServerComm:CreateSignal()`.
]=]
export type RemoteSignal = {
	--[=[
		@within RemoteSignal
		@interface Connection
		.Disconnect () -> nil
		.Connected boolean

		Represents a connection.
	]=]
	new: (parent: Instance, name: string, unreliable: boolean?, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?) -> RemoteSignal,
	--[=[
		@return boolean
		Returns `true` if the underlying RemoteSignal is bound to an
		UnreliableRemoteEvent object.
	]=]
	IsUnreliable: (self: RemoteSignal) -> boolean,
	--[=[
		@param fn (player: Player, ...: any) -> nil -- The function to connect
		@return Connection
		Connect a function to the signal. Anytime a matching ClientRemoteSignal
		on a client fires, the connected function will be invoked with the
		arguments passed by the client.
	]=]
	Connect: (self: RemoteSignal, fn: (player: Player, ...any) -> nil) -> nil,
	--[=[
		@param player Player -- The target client
		@param ... any -- Arguments passed to the client
		Fires the signal at the specified client with any arguments.

		:::note Outbound Middleware
		All arguments pass through any outbound middleware (if any)
		before being sent to the clients.
		:::
	]=]
	Fire: (self: RemoteSignal, player: Player, ...any) -> nil,
	--[=[
		@param ... any
		Fires the signal at _all_ clients with any arguments.

		:::note Outbound Middleware
		All arguments pass through any outbound middleware (if any)
		before being sent to the clients.
		:::
	]=]
	FireAll: (self: RemoteSignal, ...any) -> nil,
	--[=[
		@param ignorePlayer Player -- The client to ignore
		@param ... any -- Arguments passed to the other clients
		Fires the signal to all clients _except_ the specified
		client.

		:::note Outbound Middleware
		All arguments pass through any outbound middleware (if any)
		before being sent to the clients.
		:::
	]=]
	FireExcept: (self: RemoteSignal, ignorePlayer: Player, ...any) -> nil,
	--[=[
		@param predicate (player: Player, argsFromFire: ...) -> boolean
		@param ... any -- Arguments to pass to the clients (and to the predicate)
		Fires the signal at any clients that pass the `predicate`
		function test. This can be used to fire signals with much
		more control logic.

		:::note Outbound Middleware
		All arguments pass through any outbound middleware (if any)
		before being sent to the clients.
		:::

		:::caution Predicate Before Middleware
		The arguments sent to the predicate are sent _before_ getting
		transformed by any middleware.
		:::

		```lua
		-- Fire signal to players of the same team:
		remoteSignal:FireFilter(function(player)
			return player.Team.Name == "Best Team"
		end)
		```
	]=]
	FireFilter: (self: RemoteSignal, predicate: (Player, ...any) -> boolean, ...any) -> nil,
	--[=[
		Fires a signal at the clients within the `players` table. This is
		useful when signals need to fire for a specific set of players.

		For more complex firing, see `FireFilter`.

		:::note Outbound Middleware
		All arguments pass through any outbound middleware (if any)
		before being sent to the clients.
		:::

		```lua
		local players = {somePlayer1, somePlayer2, somePlayer3}
		remoteSignal:FireFor(players, "Hello, players!")
		```
	]=]
	FireFor: (self: RemoteSignal, players: { Player }, ...any) -> nil,
	--[=[
		Destroys the RemoteSignal object.
	]=]
	Destroy: (self: RemoteSignal) -> nil
}

--[=[
	@ignore
	@prop N/A nil
	@within DependencyTypes
	RemoteProperty - sleitnick
]=]

export type RemoteProperty = {
	--[=[
		@class RemoteProperty
		@server
		Created via `ServerComm:CreateProperty()`.

		Values set can be anything that can pass through a
		[RemoteEvent](https://developer.roblox.com/en-us/articles/Remote-Functions-and-Events#parameter-limitations).

		Here is a cheat-sheet for the below methods:
		- Setting data
			- `Set`: Set "top" value for all current and future players. Overrides any custom-set data per player.
			- `SetTop`: Set the "top" value for all players, but does _not_ override any custom-set data per player.
			- `SetFor`: Set custom data for the given player. Overrides the "top" value. (_Can be nil_)
			- `SetForList`: Same as `SetFor`, but accepts a list of players.
			- `SetFilter`: Accepts a predicate function which checks for which players to set.
		- Clearing data
			- `ClearFor`: Clears the custom data set for a given player. Player will start using the "top" level value instead.
			- `ClearForList`: Same as `ClearFor`, but accepts a list of players.
			- `ClearFilter`: Accepts a predicate function which checks for which players to clear.
		- Getting data
			- `Get`: Retrieves the "top" value
			- `GetFor`: Gets the current value for the given player. If cleared, returns the top value.

		:::caution Network
		Calling any of the data setter methods (e.g. `Set()`) will
		fire the underlying RemoteEvent to replicate data to the
		clients. Therefore, setting data should only occur when it
		is necessary to change the data that the clients receive.
		:::

		:::caution Tables
		Tables _can_ be used with RemoteProperties. However, the
		RemoteProperty object will _not_ watch for changes within
		the table. Therefore, anytime changes are made to the table,
		the data must be set again using one of the setter methods.
		:::
	]=]
	new: (parent: Instance, name: string, initialValue: any, inboundMiddleware: ServerMiddleware?, outboundMiddleware: ServerMiddleware?) -> RemoteProperty,
	--[=[
		Sets the top-level value of all clients to the same value.
		
		:::note Override Per-Player Data
		This will override any per-player data that was set using
		`SetFor` or `SetFilter`. To avoid overriding this data,
		`SetTop` can be used instead.
		:::

		```lua
		-- Examples
		remoteProperty:Set(10)
		remoteProperty:Set({SomeData = 32})
		remoteProperty:Set("HelloWorld")
		```
	]=]
	Set: (self: RemoteProperty, value: any) -> nil,
	--[=[
		Set the top-level value of the property, but does not override
		any per-player data (e.g. set with `SetFor` or `SetFilter`).
		Any player without custom-set data will receive this new data.

		This is useful if certain players have specific values that
		should not be changed, but all other players should receive
		the same new value.

		```lua
		-- Using just 'Set' overrides per-player data:
		remoteProperty:SetFor(somePlayer, "CustomData")
		remoteProperty:Set("Data")
		print(remoteProperty:GetFor(somePlayer)) --> "Data"

		-- Using 'SetTop' does not override:
		remoteProperty:SetFor(somePlayer, "CustomData")
		remoteProperty:SetTop("Data")
		print(remoteProperty:GetFor(somePlayer)) --> "CustomData"
		```
	]=]
	SetTop: (self: RemoteProperty, value: any) -> nil,
	--[=[
		@param value any -- Value to set for the clients (and to the predicate)
		Sets the value for specific clients that pass the `predicate`
		function test. This can be used to finely set the values
		based on more control logic (e.g. setting certain values
		per team).

		```lua
		-- Set the value of "NewValue" to players with a name longer than 10 characters:
		remoteProperty:SetFilter(function(player)
			return #player.Name > 10
		end, "NewValue")
		```
	]=]
	SetFilter: (self: RemoteProperty, predicate: (Player, any) -> boolean, value: any) -> nil,
	--[=[
		Set the value of the property for a specific player. This
		will override the value used by `Set` (and the initial value
		set for the property when created).

		This value _can_ be `nil`. In order to reset the value for a
		given player and let the player use the top-level value held
		by this property, either use `Set` to set all players' data,
		or use `ClearFor`.

		```lua
		remoteProperty:SetFor(somePlayer, "CustomData")
		```
	]=]
	SetFor: (self: RemoteProperty, player: Player, value: any) -> nil,
	--[=[
		Set the value of the property for specific players. This just
		loops through the players given and calls `SetFor`.

		```lua
		local players = {player1, player2, player3}
		remoteProperty:SetForList(players, "CustomData")
		```
	]=]
	SetForList: (self: RemoteProperty, players: { Player }, value: any) -> nil,
	--[=[
		Clears the custom property value for the given player. When
		this occurs, the player will reset to use the top-level
		value held by this property (either the value set when the
		property was created, or the last value set by `Set`).

		```lua
		remoteProperty:Set("DATA")

		remoteProperty:SetFor(somePlayer, "CUSTOM_DATA")
		print(remoteProperty:GetFor(somePlayer)) --> "CUSTOM_DATA"

		-- DOES NOT CLEAR, JUST SETS CUSTOM DATA TO NIL:
		remoteProperty:SetFor(somePlayer, nil)
		print(remoteProperty:GetFor(somePlayer)) --> nil

		-- CLEAR:
		remoteProperty:ClearFor(somePlayer)
		print(remoteProperty:GetFor(somePlayer)) --> "DATA"
		```
	]=]
	ClearFor: (self: RemoteProperty, player: Player) -> nil,
	--[=[
		Clears the custom value for the given players. This
		just loops through the list of players and calls
		the `ClearFor` method for each player.
	]=]
	ClearForList: (self: RemoteProperty, players: { Player }) -> nil,
	--[=[
		The same as `SetFiler`, except clears the custom value
		for any player that passes the predicate.
	]=]
	ClearFilter: (self: RemoteProperty, predicate: (Player) -> boolean) -> nil,
	--[=[
		Returns the top-level value held by the property. This will
		either be the initial value set, or the last value set
		with `Set()`.

		```lua
		remoteProperty:Set("Data")
		print(remoteProperty:Get()) --> "Data"
		```
	]=]
	Get: (self: RemoteProperty) -> any,
	--[=[
		Returns the current value for the given player. This value
		will depend on if `SetFor` or `SetFilter` has affected the
		custom value for the player. If so, that custom value will
		be returned. Otherwise, the top-level value will be used
		(e.g. value from `Set`).

		```lua
		-- Set top level data:
		remoteProperty:Set("Data")
		print(remoteProperty:GetFor(somePlayer)) --> "Data"

		-- Set custom data:
		remoteProperty:SetFor(somePlayer, "CustomData")
		print(remoteProperty:GetFor(somePlayer)) --> "CustomData"

		-- Set top level again, overriding custom data:
		remoteProperty:Set("NewData")
		print(remoteProperty:GetFor(somePlayer)) --> "NewData"

		-- Set custom data again, and set top level without overriding:
		remoteProperty:SetFor(somePlayer, "CustomData")
		remoteProperty:SetTop("Data")
		print(remoteProperty:GetFor(somePlayer)) --> "CustomData"

		-- Clear custom data to use top level data:
		remoteProperty:ClearFor(somePlayer)
		print(remoteProperty:GetFor(somePlayer)) --> "Data"
		```
	]=]
	GetFor: (self: RemoteProperty, player: Player) -> any,
	--[=[
		Destroys the RemoteProperty object.
	]=]
	Destroy: (self: RemoteProperty) -> nil
}

return {}