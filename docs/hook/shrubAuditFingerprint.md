*Create a fingerprint for a connection*.

Each request has a fingerprint generated which allows bad behavior to be
tracked (like exceeding API limits).

<h3>Implementations must return</h3>

A keyed object of fingerprint values. `null` or `undefined` values will be
filtered out when doing most checks.
