*Take action before a user logs out.*

This hook allows packages to act before a user is logged out. If an error is
thrown or passed to the middleware `next` function, the logout fails.

The `req` parameter to the middleware is an instance of
[http.IncomingMessage](http://nodejs.org/api/http.html#http_http_incomingmessage).

<div class="admonition warning"><p class="admonition-title">Note</p>
  <p>
    <code>req.user</code> as well as <code>req.loggingOutUser</code> will be
    populated with the logging out user at this point.
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
