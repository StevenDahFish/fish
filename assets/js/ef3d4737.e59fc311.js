"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[961],{32137:e=>{e.exports=JSON.parse('{"functions":[],"properties":[],"types":[{"name":"self<C,S>","desc":"Type used to describe the `self` object in Client functions\\n```lua\\nfunction MyService.Client.PrintPlayer(self: fish.self<client, server>)\\n\\tprint(self.Player)\\nend\\n```","lua_type":"C & { Player: Player, Server: S, [any]: any }","source":{"line":30,"path":"src/init.lua"}},{"name":"ServiceDef<T>","desc":"The definition of a service when created using `fish.service(name, serviceDef)`","lua_type":"T & { Client: { [any]: any }?, Start: ((any) -> any)?, [any]: any }","source":{"line":11,"path":"src/Types.lua"}},{"name":"Service<T>","desc":"A service as seen in the server context","lua_type":"T & { Client: { Server: T, [any] : any }, Start: (any) -> any, [any]: any }","source":{"line":22,"path":"src/Types.lua"}},{"name":"ServiceRef","desc":"A reference to a service from the client context","lua_type":"{ [any]: any }","source":{"line":36,"path":"src/Types.lua"}},{"name":"ControllerDef<T>","desc":"The definition of a controller when created using `fish.controller(name, controllerDef)`","lua_type":"T & { Start: ((any) -> any)?, [any]: any }","source":{"line":45,"path":"src/Types.lua"}},{"name":"Controller<T>","desc":"A controller as seen in the client context","lua_type":"T & { Start: (any) -> any, [any]: any }","source":{"line":55,"path":"src/Types.lua"}}],"name":"Types","desc":"Global types used throughout the framework","source":{"line":5,"path":"src/Types.lua"}}')}}]);