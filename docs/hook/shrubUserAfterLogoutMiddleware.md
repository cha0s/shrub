*Take action after a user logs out.*

This hook allows packages to act after a user is logged out.

The `req` parameter to the middleware is an instance of
[http.IncomingMessage](http://nodejs.org/api/http.html#http_http_incomingmessage).

<div class="admonition warning"><p class="admonition-title">Note</p>
  <p>
    <code>req.user</code> will <strong>not</strong> be populated with the
    previously logged-out user at this point, but
    <code>req.loggingOutUser</code> will.
  </p>
</div>

<h3>Implementations must return</h3>

A
[middleware hook specification](guide/concepts#middleware-hook-specification).
The middleware have the following signature:

```javascript
function(req, next) {
  ...
}
```
