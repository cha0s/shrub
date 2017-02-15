*Define login strategies for users.*

This hook allows packages to define login strategies.

<h3>Implementations must return</h3>

- Client-side:

    - (string) `methodLabel` - A label used on the user login form to identify
    your login strategy e.g. `Local`.

    - (object) `fields` - [Shrub form fields definition](guide/forms) which
    are used on the login form under a subgroup for your login strategy. For
    instance, the local user login strategy defines `username`, `password`,
    `submit` and a `forgot` markup link.

- Server-side:
  <ul><li><p>
    (mixed) `...` - A concrete strategy for the underlying authentication
    framework that is active for the site. By default this is
    [`shrub-passport`](source/packages/shrub-passport) which requires a
    strategy to implement a `passportStrategy` field e.g. an instance of
    `require('passport-local').Strategy`.
  </p></li></ul>
