*Define third-party Angular modules to include as application dependencies.*

Angular modules are defined as a dependency tree. Since we would have to edit
the application file to include those dependencies when defining the `shrub`
top-level application module (And we don't want to do that), we need a better
solution. `angularPackageDependencies` is that solution.

Shrub provides the
[`shrub-html5-notification`](packages#shrub-html5-notification) package, which
uses the
[angular-notification](https://github.com/neoziro/angular-notification) module.
The name of the module is `notification`, so the hook implementation looks
like:

```javascript
registrar.registerHook('shrubAngularPackageDependencies', function() {

  return [
    'notification'
  ];
});
```

This ensures our application has the `notification` module marked as a
dependency. You will still need to use the
[`shrubGruntConfig`](hooks/#shrubgruntconfig) hook to provide the actual
JavaScript assets to the client.

### Answer with

An array of strings naming the modules you want to include.
