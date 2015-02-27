*Take action after a user logs in.*

This hook allows packages to act after a user is logged in.

The `req` parameter to the middleware is an instance of
[http.IncomingMessage](http://nodejs.org/api/http.html#http_http_incomingmessage).

`req.user` will be populated with the newly logged in user at this point.

<h3>Implementations must return</h3>

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(req, next) {
  ...
}
```
