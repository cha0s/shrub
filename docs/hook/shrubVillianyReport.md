*Report villianous actions.*

You may bypass limit checks by returning `SKIP` (`shrub-limiter` package) from
implementations of this hook, e.g.

```javascript

registrar.registerHook('shrubLimiterCheck', function(req) {

  if (req.somethingWeWantToCheck) {
    return require('shrub-limiter').SKIP;
  }
})

```

Returning any other value besides `SKIP` will have no effect.

<h3>Implementation arguments</h3>

* (http.IncomingMessage) `req`: The route request object.
* (Number) `score`: The numeric score this action contributes towards a ban.
* (String) `key`: A unique key for this villianous action.
* (String Array) `excludedKeys`: Fingerprint keys to exclude from ban.

<h3>Implementations must return</h3>

A boolean or a promise that resolves to boolean indicating whether or not the
villianous action results in a ban.
