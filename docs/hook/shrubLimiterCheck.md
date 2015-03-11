*Specifiy criteria which will skip limiter checks.*

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

<h3>Implementations must return</h3>

`SKIP` to skip the limiter check, or anything else otherwise.
