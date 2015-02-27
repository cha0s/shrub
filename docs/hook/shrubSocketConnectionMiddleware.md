*Act after a socket connection.*

Packages may implement this hook to take action after a socket is connected.

The `req` parameter to the middleware is an instance of
[http.IncomingMessage](http://nodejs.org/api/http.html#http_http_incomingmessage)
from the HTTP request.

The `res` parameter to the middleware is an instance of
[http.ServerResponse](http://nodejs.org/api/http.html#http_class_http_serverresponse)
from the HTTP request.

<h3>Implementations must return</h3>

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(req, res, next) {
  ...
}
```
