# Hook system

Hooks are how Shrub allows packages to implement (or invoke) dynamic
behavior. Hooks can also serve as a form of message passing between
packages.

To implement a hook, export a `pkgmanRegister` method which takes a
`registrar` argument, and use the registrar to register your hook:

```javascript

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('someHook', function() {
    doStuff();
  }

  registrar.registerHook('someOtherHook', function(arg) {
    doOtherStuffWith(arg);
  }
}

```

To invoke a hook, require `pkgman` and use the `invoke` method:

```javascript

var pkgman = require('pkgman');

var results = pkgman.invoke('someOtherHook', arg);

```

Any arguments following the hook name will be passed along to the
implementations. Hooks are invoked synchronously. For more information
about `pkgman`, see

###### TODO: Link to `pkgman` documentation when complete.
## angularNavigationMiddleware

### 1 implementation(s)

* packages/shrub-form ([server](source/packages/shrub-form#implements-hook-angularnavigationmiddleware))

## appConfig

### 1 invocation(s)

* client/app ([client](source/client/app#invoke-hook-appconfig))

## appRun

### 1 invocation(s)

* client/app ([client](source/client/app#invoke-hook-apprun))

## augmentDirective

### 1 invocation(s)

* client/packages ([client](source/client/packages#invoke-hook-augmentdirective))

## bootstrapMiddleware

### 1 invocation(s)

* server ([server](source/server#invoke-hook-bootstrapmiddleware))

## controller

### 1 invocation(s)

* client/packages ([client](source/client/packages#invoke-hook-controller))

## directive

### 1 invocation(s)

* client/packages ([client](source/client/packages#invoke-hook-directive))

## filter

### 1 invocation(s)

* client/packages ([client](source/client/packages#invoke-hook-filter))

## httpMiddleware

### 1 implementation(s)

* packages/shrub-form ([server](source/packages/shrub-form#implements-hook-httpmiddleware))

## preBootstrap

*Invoked before the application bootstrap phase.*

### Mitigate slow build times

If your package `require`s heavy modules, you should require them in an
implementation of hook `preBootstrap`. For instance, say you have a package
like:

```javascript
var someHeavyModule = require('some-heavy-module');

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('someHook', function() {
    someHeavyModule.doSomething();
  }
}

```

This will slow the build process down, since `some-heavy-module` must be
loaded when loading your package. Use this pattern instead:

```javascript
var someHeavyModule = null;

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('preBootstrap', function() {
    someHeavyModule = require('some-heavy-module');
  }

  registrar.registerHook('someHook', function() {
    someHeavyModule.doSomething();
  }
}

```

So that the heavy module will not be `require`d until hook `preBootstrap` is
invoked.


### 1 invocation(s)

* server ([server](source/server#invoke-hook-prebootstrap))

## processExit

### 1 invocation(s)

* server ([server](source/server#invoke-hook-processexit))

## provider

### 1 invocation(s)

* client/packages ([client](source/client/packages#invoke-hook-provider))

## service

### 1 invocation(s)

* client/packages ([client](source/client/packages#invoke-hook-service))

