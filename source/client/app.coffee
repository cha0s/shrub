```coffeescript
```
# Client application entry point.

*Definition of the main top-level Angular module, with dependency gathering
and config/run hook invocation.*

Top-level module.
```coffeescript
angular.module 'shrub', ['shrub.core']
```
Include core Angular dependencies.
```coffeescript
coreDependencies = []
coreDependencies.push 'ngRoute'
coreDependencies.push 'ngSanitize'
```
`packageDependencies` will be automatically generated and populated by
Grunt.

See the documentation for
[`shrubAngularPackageDependencies`](../../hooks/#shrubangularpackagedependencies).
```coffeescript
coreDependencies.push packageDependencies...
```
Include core shrub dependencies.
```coffeescript
coreDependencies.push 'shrub.config'
coreDependencies.push 'shrub.packages'
coreDependencies.push 'shrub.require'
```
Define the core Shrub module.
```coffeescript
angular.module('shrub.core', coreDependencies)

  .config([
    '$injector', 'shrub-pkgmanProvider'
    ({invoke}, {invokeFlat}) ->
```
#### Invoke hook `shrubAngularAppConfig`.

Invoked when the Angular application is in the configuration phase.
Implementations should return an [annotated
function](http://docs.angularjs.org/guide/di#dependency-annotation).
```coffeescript
      invoke injectable for injectable in invokeFlat 'shrubAngularAppConfig'

      return

  ])

  .run([

    '$injector', 'shrub-pkgman'
    ({invoke}, {invokeFlat}) ->
```
#### Invoke hook `shrubAngularAppRun`.

Invoked when the Angular application is the run phase. Implementations
should return an [annotated
function](http://docs.angularjs.org/guide/di#dependency-annotation).
```coffeescript
      invoke injectable for injectable in invokeFlat 'shrubAngularAppRun'

      return

  ])
```
