*Define middleware to run when Angular is navigated in its sandbox.*

Angular sandboxes retain navigation (and other) state for a client without
JavaScript capability. When a user hits another page on the server, the
sandbox navigates the Angular application to the new path. If the path
changed, the middleware collected by this hook are dispatched, allowing
packages to react to the navigation change.

The `req` parameter to the middleware is the original HTTP request object,
along with the following extra properties:

* (Sandbox) `sandbox` - The sandbox instance.

### Answer with

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
