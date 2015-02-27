*Define RPC routes.*

Packages use this hook to define RPC routes.

<h3>Implementations must return</h3>

An array of objects structured like:

* (String) `path` - The HTTP path of the route. Include the leading slash.
* (Function) `receiver` - The function invoked when the route is hit. Takes two
  parameters:
    * (http.IncomingMessage) `req` - The request object.
    * (Function) `fn` - A nodeback called when the route is complete.
* (...) - Other packages may expect arbitrary parameters, for instance
  `shrub-limiter` expects a key `limiter`. See
  [the documentation](source/packages/shrub-limiter/#implements-hook-shrubrpcroutesalter)
  for more information.