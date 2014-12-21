
_$injector = null

exports.setInjector = ($injector) -> _$injector = $injector

exports.inject = (injectable) -> $_injector.invoke injectable
