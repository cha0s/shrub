*Define assets to serve to the client application.*

Packages may come bundled with JavaScript or CSS assets. This hook is how you
can provide them to the client application.

Asset middleware takes `assets` as its first argument. This is an object with
the following properties:

* (String Array) `scripts` - A list of script assets.
* (String Array) `stylesheets` - A list of sylesheet assets.

**NOTE**: This hook lets you serve assets, but will not automatically copy
them from your package to the `app` directory where they will be served.
You'll need to implement the [`gruntConfig`](hooks/#gruntconfig) hook for that.

### Answer with

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(assets, next) {
  ...
}
```
