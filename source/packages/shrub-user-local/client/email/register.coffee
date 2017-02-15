# User - Register email
```coffeescript
config = require 'config'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularDirective`.
```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    'shrub-ui/window-title'
    (windowTitle) ->

      directive = {}

      directive.link = (scope) ->

        windowTitle.setPage 'Registration details'

        scope.siteName = config.get 'packageConfig:shrub-core:siteName'

      directive.scope = true

      directive.template = '''

<p>
  Hello, <span
    data-ng-bind="user.name"
  ></span>!
</p>

<p>
  You (or someone using your email address) registered an account with us just now.
</p>

<p>
  You may <a
    data-ng-href="{{loginUrl}}"
  >visit the login link for your account</a> at <a
    data-ng-bind="loginUrl"
    data-ng-href="{{loginUrl}}"
  >
  </a> to set your password!
</p>

<p>
  Regards,
</p>

<p>
  <a
    data-ng-bind="siteName"
    data-ng-href="{{siteUrl}}"
  ></a>
</p>

<p>—</p>

<p class="muted">
  <small>
    If you received this email by mistake, feel free to ignore it. Have a lovely day!
  </small>
</p>

<p class="muted">
  <small>
    This is an automatically generated email; <strong
    >if you reply it may not be read by anyone.</strong>
  </small>
</p>

'''

      directive

  ]
```
