*Define server-side configuration settings.*

Packages may use this hook to define default configuration for server-side
functionality. These settings can be overridden in the settings file.

<h3>Implementations must return</h3>

A recursive object which will be folded into the server configuration under
the package name key. For instance, say we have a package `my-package` which
defines the hook like:

```javascript
registrar.registerHook('shrubConfigServer', function() {
  return {
    one: 68,
    two: {
      three: 419
    }
  };
});
```

You would then find those values in the configuration at:

```javascript
config.get('packageSettings:my-package:one');
config.get('packageSettings:my-package:two:three');
```
