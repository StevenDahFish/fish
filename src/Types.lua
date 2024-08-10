export type ServiceDef<T> = T & {
	Client: { [any]: any }?,
	Start: ((any) -> any)?,
	[any]: any
}

export type Service<T> = T & {
	Client: {
		Server: T,
		[any] : any 
	},
	Start: (any) -> any,
	[any]: any
}

export type ServiceRef = {
	[any]: any
}

export type ControllerDef<T> = T & {
	Start: ((any) -> any)?,
	[any]: any
}

export type Controller<T> = T & {
	Start: (any) -> any,
	[any]: any
}

return {}