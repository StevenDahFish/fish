---
title: Mutex
sidebar_position: 2
---

A [Mutex](https://en.wikipedia.org/wiki/Mutual_exclusion) allows you to make sure only one thread can run a section of code (*critical section*) at a time. This is useful for client functions that yield in between reading and writing data, such as saving to a DataStore or purchasing an item, where a client calling the same function multiple times at once could cause issues like spending money twice.

Every [service client function](../services.md#adding-client-functions-to-a-service) and [service client signal](../services.md#signals) has its own Mutex, which can be accessed by using `self.Mutex`. See the [API](/api/Types#Mutex) for all of its functions.

## Global & Player Locks
Each Mutex contains two kinds of locks:
* **Global lock**, which is a single lock shared between every player calling that client function. Use this when the critical section changes something that every player shares, such as a limited stock item in a shop.
* **Player lock**, which is a lock that is separate for each player. Use this when the critical section only changes something that belongs to that player, such as their own money. Players will not have to wait for each other.

The global lock and player locks are **independent** of each other. Holding a player lock will not block the global lock, and holding the global lock will not block any player locks.

## Locking & Unlocking
Use `self.Mutex:Lock()` to lock and `self.Mutex:Unlock()` to unlock. If the lock is already held by another thread, the current thread will wait until it is unlocked. Waiting threads get the lock in the same order they started waiting.
```luau
function MyService.Client.BuyItem(self: fish.self<client, self>, itemName: string): boolean
	self.confirm(t.string(itemName))

	-- Global lock
	self.Mutex:Lock()
	-- Run critical section
	self.Mutex:Unlock()

	-- Player lock
	self.Mutex:Lock(nil, self.Player)
	-- Run critical section
	self.Mutex:Unlock(self.Player)

	return true
end
```
:::caution
A lock can only be unlocked from the same thread that locked it. Calling `self.Mutex:Unlock()` when the lock isn't held or from a different thread (e.g. inside of `task.spawn()`) will result in an error.
:::

### Re-entrant Locking
If a thread locks a lock that it is already holding, it will not wait for itself. Instead, the lock will keep track of how many times it has been locked, and will only be released once it has been unlocked the same amount of times.
```luau
self.Mutex:Lock()
self.Mutex:Lock()
self.Mutex:Unlock()
-- Still locked
self.Mutex:Unlock()
-- Released
```

### Expected Max Runtime
The first parameter of `self.Mutex:Lock()` is the amount of seconds you expect the lock to be held for. If the lock is held for longer than this, a [warning](#warnings) will be outputted. Pass `nil` if you don't want to check for this.
```luau
-- Warns if the lock is held for longer than 5 seconds
self.Mutex:Lock(5, self.Player)
-- Run critical section
self.Mutex:Unlock(self.Player)
```

## Wrapping
Instead of locking and unlocking manually, you can wrap a function using `self.Mutex:Wrap()` for the global lock or `self.Mutex:WrapPlayer()` for a player lock. The lock will be held while the function runs and released once it is done. Similar to `pcall()`, it returns whether the function succeeded, followed by the values returned by the function.

The wrapped function runs on its own thread, so it is given its own [confirm](index.md#confirm) as the first parameter. Any extra parameters passed in after the function will be passed to it.
```luau
-- Global lock
const success, result = self.Mutex:Wrap(nil, function(confirm, parameter)
	-- Run critical section
	return parameter
end, 1)
print(success, result) --> Output: true, 1

-- Player lock, warning if the lock is held for longer than 5 seconds
const success, money = self.Mutex:WrapPlayer(5, self.Player, function(confirm, amount)
	confirm(amount > 0)
	-- Run critical section
	return amount
end, 10)
```
* If `confirm` fails inside of the wrapped function, it returns `false, "Silent assertion failed."`.
* If the wrapped function errors, it returns `false` along with the error message. The error will still be outputted with where it was wrapped.

## Automatic Unlocking
When a client function ends, whether it returned, errored, or was stopped by `self.confirm()`, any locks still held by the thread running that client function will automatically be released. This prevents a lock from being held forever and every other player waiting on it.
:::caution
* Only locks held by the thread running the client function are released. Locks held by other threads (e.g. inside of `task.spawn()`) will not be released.
* If `self.confirm()` and Mutex safety have been [disabled](index.md#disabling-confirm), locks will **not** be released if an error occurs before they are unlocked.
:::

## Warnings
The Mutex will output warnings to help you find issues with how locks are used. Each warning includes the name of the client function, the player's user id if it's a player lock, and where the lock was locked. Warnings of the same kind are rate limited per lock.
* **High depth**, when a lock has been [re-entered](#re-entrant-locking) too many times. This usually means a missing `Unlock()` or recursion.
* **Large queue**, when too many threads are waiting on a lock. This usually means usage is high or a lock is being held for too long. The threshold for the global lock grows with the amount of players in the server.
* **Held longer than expected**, when a lock is held for longer than its [expected max runtime](#expected-max-runtime).

### Current Values
| Setting | Value |
| --- | --- |
| High depth threshold (global lock) | More than 4 |
| High depth threshold (player lock) | More than 4 |
| Large queue threshold (global lock) | More than 10 × the amount of players (minimum of 10) |
| Large queue threshold (player lock) | More than 10 |
| Rate limit for each kind of warning | Once every 5 seconds |
| How often held time is checked | Every 0.25 seconds |

## Limitations
:::warning
The wrapped function in `self.Mutex:Wrap()` and `self.Mutex:WrapPlayer()` runs on a different thread than the one that locked it. Because of this, using the same lock again inside of the wrapped function will not work as expected:
* `self.Mutex:Lock()`, `self.Mutex:Wrap()`, or `self.Mutex:WrapPlayer()` on the same lock will wait forever.
* `self.Mutex:Unlock()` on the same lock will result in an error.

This behavior may be changed in the future.
:::
