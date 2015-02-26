*Add to the REPL context.*

Packages may use this hook to provide access to parts of their state to the
REPL context.

Implementations accept the following arguments:

* (Object) `context` - The context object.

To set context variables, simply set them on the context object.
