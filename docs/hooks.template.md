# Hook system

Hooks are how Shrub allows packages to implement (or invoke) dynamic behavior.
Hooks can also serve as a form of message passing between packages.

To implement a hook, export a `pkgmanRegister` method which takes a `registrar`
argument, and use the registrar to register your hook:

```javascript

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('someHook', function() {
    doStuff();
  }

  registrar.registerHook('someOtherHook', function(arg) {
    doOtherStuffWith(arg);
  }
};

```

To invoke a hook, require `pkgman` and use the `invoke` method:

```javascript

var pkgman = require('pkgman');

var results = pkgman.invoke('someOtherHook', arg);

```

Any arguments following the hook name will be passed along to the
implementations. Hooks are invoked synchronously. For more information about
`pkgman`, see

###### TODO: Link to `pkgman` documentation when complete.
