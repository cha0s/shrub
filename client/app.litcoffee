
# Application entry point.

Top-level module.

    angular.module 'shrub', ['shrub.core']

Include core Angular dependencies.

    coreDependencies = []
    coreDependencies.push 'ngRoute'
    coreDependencies.push 'ngSanitize'

`packageDependencies` will be automatically generated and populated by Grunt.
Packages implement the hook `angularPackageDependencies` to specify their
3rd-party module dependencies.

###### TODO: Link this to where this happens in Grunt for illustration.

    coreDependencies.push packageDependencies...

Include core shrub dependencies.

    coreDependencies.push 'shrub.config'
    coreDependencies.push 'shrub.packages'
    coreDependencies.push 'shrub.require'

Define the core Shrub module.

    angular.module('shrub.core', coreDependencies)

      .config([
        '$injector', 'shrub-pkgmanProvider'
        ({invoke}, {invokeFlat}) ->

#### Invoke hook `appConfig`.

Invoked when the Angular application is in the configuration phase.

          invoke injectable for injectable in invokeFlat 'appConfig'

      ])

      .run([

        '$injector', 'shrub-pkgman'
        ({invoke}, {invokeFlat}) ->

#### Invoke hook `appRun`.

Invoked when the Angular application is the run phase. This is where things
begin to get interesting. :)

          invoke injectable for injectable in invokeFlat 'appRun'

      ])
