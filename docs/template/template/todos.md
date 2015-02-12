
# TODO list

Shrub -- like any project -- always presents a path for improvement. This is
a dynamically generated listing of TODO items, each with a line of code
context.


[client/modules/middleware.coffee](./client/modules/middleware.html)

* #### `configKey = if global? then 'packageSettings' else 'packageConfig'`

   this really should be unified, making this unnecessary.

[packages/shrub-angular/index.coffee](./packages/shrub-angular/index.html)

* #### `return`

   need to extract params to build redirectTo, small enough mismatch to ignore for now.

[packages/shrub-core/client/index.coffee](./packages/shrub-core/client/index.html)

* #### `route.template ?= ' '`

   Some method of allowing `templateUrl`.

[packages/shrub-form/index.coffee](./packages/shrub-form/index.html)

* #### `return next() unless body.formKey?`

   CRSF check needed here.

[packages/shrub-limiter/limiter.coffee](./packages/shrub-limiter/limiter.html)

* #### `module.exports = class Limiter`

   Rewrite this comment

[packages/shrub-ui/client/list/index.coffee](./packages/shrub-ui/client/list/index.html)

* #### `)`

   Fix this when menu handles existing classes more intelligently. element.addClass scope.list.name if scope.list?.name

[packages/shrub-user/client/index.coffee](./packages/shrub-user/client/index.html)

* #### `service.login = (method, username, password) ->`

   username and password are tightly coupled to local strategy. Change that.

* #### `service.fakeLogin = (username, password, id) ->`

   This will change when login method generalization happens.

[packages/shrub-user/forgot.coffee](./packages/shrub-user/forgot.html)

* #### `loginUrl: "#{`

   HTTPS

[packages/shrub-user/login.coffee](./packages/shrub-user/login.html)

* #### `LocalStrategy = require('passport-local').Strategy`

   Strategies should be dynamically defined through a hook.

[packages/shrub-user/register.coffee](./packages/shrub-user/register.html)

* #### `loginUrl: "#{`

   HTTPS
