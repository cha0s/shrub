*Final cleanups as the process is exiting.*

Shrub tries its hardest to always invoke this hook, even in the event of a
raised signal or unhandled exception.

You should not schedule asynchronous events, as they will not be dispatched.
See [the Node.js documentation](http://nodejs.org/api/process.html#process_event_exit)
for more information.
