*Define HTTP routes.*

Packages use this hook to define HTTP routes.

<h3>Implementations must return</h3>

An array of objects structured like:

* (String) `path` - The HTTP path of the route. Include the leading slash.
* (String) `verb` - The HTTP verb to associate with this route. Defaults to
  `'get'`.
* (Function) `receiver` - The function invoked when the route is hit. Takes
  three parameters:
    * (http.IncomingMessage) `req` - The request object.
    * (http.ServerResponse) `res` - The response object.
    * (Function) `fn` - A nodeback called when the route is complete.
