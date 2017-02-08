<h1>Package system</h1>

Shrub is organized into packages which implement hooks.

A package is essentially a node.js module. Exporting a `pkgmanRegister`
function allows shrub to register your package in its package manager. This is
how you can implement hooks, allowing you to augment, modify, and even define
Shrub's behavior.

The simplest example of a package would be something like:

```javascript
exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('shrubCorePreBootstrap', function() {
    console.log('I hooked into shrub!');
  });
};
```

This package simply hooks into the
[`shrubCorePreBootstrap`](../hooks#shrubcoreprebootstrap) hook and logs
a message to the console when that hook is invoked. Obviously this particular
package isn't super useful!

Hooks are how Shrub allows packages to implement (or invoke) dynamic behavior.
Hooks can also serve as a form of message passing between packages.

You can do anything from
[defining an Angular directive](../hooks#shrubangulardirective)
to [specifying model collections](../hooks#shrubormcollections). See the
[hook reference](../hooks) to learn more about the hooks that come
included with shrub's core packages.

To implement a hook, export a `pkgmanRegister` method which takes a `registrar`
argument, and use the registrar to register your hook:

```javascript
exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('someHook', function() {
    doStuff();
  });

  registrar.registerHook('someOtherHook', function(arg) {
    doOtherStuffWith(arg);
  });
};
```

To invoke a hook, require `pkgman` and use the `invoke` method:

```javascript
var pkgman = require('pkgman');

var results = pkgman.invoke('someOtherHook', arg);
```

Any arguments following the hook name will be passed along to the
implementations. Hooks are invoked synchronously. For more information about
`pkgman`, see [the pkgman documentation](../source/client/modules/pkgman/).
