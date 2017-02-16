*Take action after a user logs in.*

This hook allows packages to act after a user is logged in.

The `req` parameter to the middleware is an instance of
[http.IncomingMessage](http://nodejs.org/api/http.html#http_http_incomingmessage).

<div class="admonition warning"><p class="admonition-title">Note</p>
  <p>
    <code>req.user</code> as well as <code>req.loggingInUser</code> will be
    populated with the newly logged-in user at this point.
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
