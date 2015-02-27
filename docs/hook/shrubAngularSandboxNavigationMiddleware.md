*Define middleware to run when Angular is navigated in its sandbox.*

Angular sandboxes retain navigation (and other) state for a client without
JavaScript capability. When a user hits another page on the server, the
sandbox navigates the Angular application to the new path. If the path
changed, the middleware collected by this hook are dispatched, allowing
packages to react to the navigation change.

The `req` parameter to the middleware is an instance of
[http.IncomingMessage](http://nodejs.org/api/http.html#http_http_incomingmessage)
from the original HTTP request, along with the following extra properties:

* (Sandbox) `sandbox` - The sandbox instance.

<h3>Implementations must return</h3>

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(req, next) {
  ...
}
```
