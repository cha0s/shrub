*Define persistent notification queues.*

Packages may implement this hook to define queues of notifications.

<h3>Implementations must return</h3>

An object whose keys are queue names and whose values are structured like:

* (Function) `channelFromRequest` - An idempotent function which returns the
  channel of the queue. The channel is represented as a string value.
  Typically the channel maps to the concept of ownership -- a queue which
  stores some notifications for a user will likely belong to a channel
  which is identical to the user ID. This function takes the following
  parameters:
    * (http.IncomingMessage) `req` - The request object.
