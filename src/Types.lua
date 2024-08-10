--[=[
	The definition of a service when created using `fish.service(name, serviceDef)`
]=]
export type ServiceDef<T> = T & {
	Client: { [any]: any }?,
	Start: ((any) -> any)?,
	[any]: any
}

--[=[
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
	A reference to a service from the client context
]=]
export type ServiceRef = {
	[any]: any
}

--[=[
	The definition of a controller when created using `fish.controller(name, controllerDef)`
]=]
export type ControllerDef<T> = T & {
	Start: ((any) -> any)?,
	[any]: any
}

--[=[
	A controller as seen in the client context
]=]
export type Controller<T> = T & {
	Start: (any) -> any,
	[any]: any
}

return {}