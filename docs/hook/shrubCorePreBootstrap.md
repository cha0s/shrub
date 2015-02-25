*Invoked before the application bootstrap phase.*

### Mitigate slow build times

If your package `require`s heavy modules, you should require them in an
implementation of hook `shrubCorePeBootstrap`. For instance, say you have a
package like:

```javascript
var someHeavyModule = require('some-heavy-module');

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('someHook', function() {
    someHeavyModule.doSomething();
  });
};
```

This will slow the build process down, since `some-heavy-module` must be
loaded when loading your package. Use this pattern instead:

```javascript
var someHeavyModule = null;

exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('shrubCorePeBootstrap', function() {
    someHeavyModule = require('some-heavy-module');
  });

  registrar.registerHook('someHook', function() {
    someHeavyModule.doSomething();
  });
};
```

So that the heavy module will not be `require`d until hook
`shrubCorePeBootstrap` is invoked.
