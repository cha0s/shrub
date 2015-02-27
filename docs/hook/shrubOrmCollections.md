*Define collections of models.*

Packages can implement this hook to define collections of models for use
throughout the server (and to a limited extent, the client) application.

Shrub uses Waterline as an ORM, so you can follow the
[Waterline documentation for how to define model collections](https://github.com/balderdashy/waterline-docs/blob/master/models.md).
Shrub handles calling `Waterline.Collection.extend`, so you only have to return
the raw object.

<h3>Implementations must return</h3>

A keyed object whose values are raw model collection objects. e.g.

```javascript
exports.pkgmanRegister = function(registrar) {

  registrar.registerHook('shrubOrmCollections', function() {

    return {
      'some-model': {
        attributes: {
          foo: 'string'
        }
      },
      'some-other-model': {
        attributes: {
          bar: 'string'
        }
      }
    };
  });
};
```
