# # Angular augmentation module
#
# *Provides functionality related to Angular for client packages.* Allow shrub
# to set the injector.
_$injector = null
exports.setInjector = ($injector) -> _$injector = $injector

# Inject dependencies into an [annotated
# function](http://docs.angularjs.org/guide/di#dependency-annotation).
# Packages may use this to inject dependencies out-of-band.
exports.inject = (injectable) -> _$injector.invoke injectable