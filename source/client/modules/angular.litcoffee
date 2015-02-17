# Angular augmentation module

*Provides functionality related to Angular for client packages.*

Allow shrub to set the injector. This can only be called once, so packages
won't be able to corrupt it.

    _$injector = null
    exports.setInjector = ($injector) ->
      _$injector = $injector
      exports.setInjector = undefined

Inject dependencies into an
[annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).
Packages may use this to inject dependencies out-of-band.

    exports.inject = (injectable) -> $_injector.invoke injectable
