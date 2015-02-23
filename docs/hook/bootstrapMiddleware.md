*Define middleware to run when the server application is bootstrapping.*

This hook is where most of the major initialization work happens on the
Shrub server. [`shrub-http`](packages/#shrub-http) spins up an HTTP server,
[`shrub-orm`](packages/#shrub-orm) spins up Waterline, and more.

### Answer with

A
[middleware hook specification](guide/concepts/#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(next) {
  ...
}
```
