*Finish up an RPC route call.*

This hook gives packages the chance to run some code after an RPC route
finishes. For instance, [`shrub-session`](packages/#shrub-session) and
[`shrub-user`](packages/#shrub-user) use this hook to update the session and
user records (respectively) after each RPC call.

### Answer with

A promise which when fulfilled allows the RPC call to finish.
