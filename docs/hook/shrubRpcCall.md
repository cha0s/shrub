*Notify packages when any RPC call is made.*

Packages can implement this hook to be notified when any RPC call is made.
For instance, [`shrub-ui/messages`](packages/#shrub-uimessagesclient) uses
this hook to display an error message if any RPC call returned with an error.

<h3>Implementations must return</h3>

An [annotated function](guide/concepts#annotated-functions). The following
locals are injected:

* (String) `route` - The RPC route path.
* (Any) `data` - The data sent to the server.
* (Promise) `result` - The result promise.
