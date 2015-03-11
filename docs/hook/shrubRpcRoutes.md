*Define RPC routes.*

Packages use this hook to define RPC routes.

<h3>Implementations must return</h3>

An array of objects structured like:

* (String) `path` - The HTTP path of the route. Include the leading slash.
* (Function Array) `middleware` - A middleware stack which is dispatched when
  the route is hit. The middleware have the following signature:

```javascript
function(req, res, next) {
  ...
}
```

`req` has the following properties set by default:

* (Any) `body`: The data passed in from the RPC call.
* (Object) `route`: the route definition object specified above.
* (Socket) `socket`: The raw socket object.

`res` has the following properties set by default:

* (Function) `end`: Called with the data to respond to the RPC call.
