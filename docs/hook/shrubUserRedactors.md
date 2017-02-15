*Define functions to redact objects for users.*

This hook allows packages to define redaction functions that take an object
and a user and redact the object based on a user's permissions. For instance,
[`shrub-user-local`](source/packages/shrub-user-local) defines redactors for
`shrub-user-local` models, which prune the `password` and `salt` fields. The
redactor also checks if the local user belongs to the same user on whose
behalf the redaction is occuring. If it's the same user, the redactor decrypts
and includes the `email` field. Otherwise, the `email` field is completely
redacted.

<h3>Implementations must return</h3>

An object whose keys correspond to object types (a rule of thumb is to use
the model name e.g. `shrub-user`, `shrub-user-local`, etc.) and whose value is
an array of redaction functions.

Supposing we wanted to implement a redaction function which would redact the
`name` field for a `shrub-user-local` model, we could implement it like so:

```coffeescript
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubUserRedactors`.
  registrar.registerHook 'shrubUserRedactors', ->

    'shrub-user-local': [

      (object, user) ->

        delete object.name
        return object

    ]
```

<div class="admonition warning"><p class="admonition-title">Note</p>
  <p>
    Redaction functions may return a promised redacted object.
  </p>
</div>
