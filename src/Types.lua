--[=[
	@class Types
	Global types used throughout the framework
]=]

--[=[
	@type ServiceDef<T> T & { Client: { [any]: any }?, Start: ((any) -> any)?, [any]: any }
	@within Types
	The definition of a service when created using `fish.service(name, serviceDef)`
]=]
export type ServiceDef<T> = T & {
	Client: { [any]: any }?,
	Start: ((any) -> any)?,
	[any]: any
}

--[=[
	@type Service<T> T & { Client: { Server: T, [any] : any }, Start: (any) -> any, [any]: any }
	@within Types
	A service as seen in the server context
]=]
export type Service<T> = T & {
	Client: {
		Server: T,
		[any] : any 
	},
	Start: (any) -> any,
	[any]: any
}

--[=[
	@type ServiceRef { [any]: any }
	@within Types
	A reference to a service from the client context
]=]
export type ServiceRef = {
	[any]: any
}

--[=[
	@type ControllerDef<T> T & { Start: ((any) -> any)?, [any]: any }
	@within Types
	The definition of a controller when created using `fish.controller(name, controllerDef)`
]=]
export type ControllerDef<T> = T & {
	Start: ((any) -> any)?,
	[any]: any
}

--[=[
	@type Controller<T> T & { Start: (any) -> any, [any]: any }
	@within Types
	A controller as seen in the client context
]=]
export type Controller<T> = T & {
	Start: (any) -> any,
	[any]: any
}

return {}