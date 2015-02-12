# TODO list

Shrub -- like any project -- always presents a path for improvement. This
is a dynamically generated list of TODO items, each with context.

> `packageDependencies` will be automatically generated and populated by Grunt.
> Packages implement the hook `angularPackageDependencies` to specify their
> 3rd-party module dependencies.
> 
>## TODO: Link this to where this happens in Grunt for illustration.
> 
>     coreDependencies.push packageDependencies...
> 

###### the above found in [client/app.litcoffee:20](source/client/app#todo-link-this-to-where-this-happens-in-grunt-for-illustration)

> Invoked before the application bootstrap phase.
> 
> [See the `preBootstrap` hook documentation](hooks#prebootstrap)
> 
>## TODO: Link to an instance of this in shrub core.
> 
>       debugSilly 'Pre bootstrap phase...'
>       pkgman.invoke 'preBootstrap'

###### the above found in [server.litcoffee:38](source/server#todo-link-to-an-instance-of-this-in-shrub-core)

> 
> Invoked during the application bootstrap phase. Packages implementing this hook
> should return an instance of `MiddlewareGroup`.
> 
>## TODO: Link to an instance of this in shrub core.
> 
> ###### TODO: Currently middleware hook implementations return an ad-hoc structure, but MiddlewareGroup will be the preferred mechanism in the future.
> 

###### the above found in [server.litcoffee:49](source/server#todo-link-to-an-instance-of-this-in-shrub-core_1)

> should return an instance of `MiddlewareGroup`.
> 
> ###### TODO: Link to an instance of this in shrub core.
> 
>## TODO: Currently middleware hook implementations return an ad-hoc structure, but MiddlewareGroup will be the preferred mechanism in the future.
> 
> This is where the real heavy-lifting instantiation occurs. For instance, this
> is where the HTTP server is constructed by `shrub-http` and made to listen on

###### the above found in [server.litcoffee:51](source/server#todo-currently-middleware-hook-implementations-return-an-ad-hoc-structure-but-middlewaregroup-will-be-the-preferred-mechanism-in-the-future)

> 
> We do our best to guarantee that hook `processExit` will always be invoked,
> even when an exception or signal arises.
> 
>## TODO: Link to an instance of this in shrub core.
> 
>       process.on 'exit', -> pkgman.invoke 'processExit'
> 

###### the above found in [server.litcoffee:80](source/server#todo-link-to-an-instance-of-this-in-shrub-core_2)
