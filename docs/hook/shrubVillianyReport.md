*Act on reported villianous actions.*

Packages can invoke this hook to notify other packages that villianous behavior
has occurred. This is an abstract concept that is application-specific: one
application in core shrub is exceeding RPC call limits, however you could use
the system for things like user flagging, abusive behavior, etc.

<h3>Implementation arguments</h3>

* (http.IncomingMessage) `req`: The route request object.
* (Number) `score`: The numeric score this action contributes towards a ban.
* (String) `key`: A unique key for this villianous action.
* (String Array) `excludedKeys`: Fingerprint keys to exclude from ban.

<h3>Implementations must return</h3>

A boolean or a promise that resolves to boolean indicating whether or not the
villianous action results in a ban.
