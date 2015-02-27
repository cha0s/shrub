*Define configuration variables to be sent to the client.*

Packages can implement this hook to pass configuration variables to the client.
Configuration is keyed by the name of the package.

Variables with `null` or `undefined` values will be filtered out and not sent
to the client.

<h3>Implementations must return</h3>

A keyed object.
