"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[966],{89039:e=>{e.exports=JSON.parse('{"functions":[],"properties":[],"types":[],"name":"RemoteProperty","desc":"Created via `ServerComm:CreateProperty()`.\\n\\nValues set can be anything that can pass through a\\n[RemoteEvent](https://developer.roblox.com/en-us/articles/Remote-Functions-and-Events#parameter-limitations).\\n\\nHere is a cheat-sheet for the below methods:\\n- Setting data\\n\\t- `Set`: Set \\"top\\" value for all current and future players. Overrides any custom-set data per player.\\n\\t- `SetTop`: Set the \\"top\\" value for all players, but does _not_ override any custom-set data per player.\\n\\t- `SetFor`: Set custom data for the given player. Overrides the \\"top\\" value. (_Can be nil_)\\n\\t- `SetForList`: Same as `SetFor`, but accepts a list of players.\\n\\t- `SetFilter`: Accepts a predicate function which checks for which players to set.\\n- Clearing data\\n\\t- `ClearFor`: Clears the custom data set for a given player. Player will start using the \\"top\\" level value instead.\\n\\t- `ClearForList`: Same as `ClearFor`, but accepts a list of players.\\n\\t- `ClearFilter`: Accepts a predicate function which checks for which players to clear.\\n- Getting data\\n\\t- `Get`: Retrieves the \\"top\\" value\\n\\t- `GetFor`: Gets the current value for the given player. If cleared, returns the top value.\\n\\n:::caution Network\\nCalling any of the data setter methods (e.g. `Set()`) will\\nfire the underlying RemoteEvent to replicate data to the\\nclients. Therefore, setting data should only occur when it\\nis necessary to change the data that the clients receive.\\n:::\\n\\n:::caution Tables\\nTables _can_ be used with RemoteProperties. However, the\\nRemoteProperty object will _not_ watch for changes within\\nthe table. Therefore, anytime changes are made to the table,\\nthe data must be set again using one of the setter methods.\\n:::","realm":["Server"],"source":{"line":212,"path":"src/DependencyTypes.lua"}}')}}]);