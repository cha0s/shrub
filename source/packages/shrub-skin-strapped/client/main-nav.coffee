# Strapped - Main navigation

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    'shrub-ui/window-title'
    (windowTitle) ->

      link: (scope, elm, attr) ->
```

Add some useful links to the nav.

```coffeescript
        scope.menu =

          name: 'main-nav'
          attributes:
            class: ['nav', 'navbar-nav', 'navbar-left']
            id: 'main-nav'
          items: []

        scope.$watch(
          -> windowTitle.page()
          -> scope.pageTitle = windowTitle.page()
        )

      template: '''

<nav class="navbar navbar-default" role="navigation">
  <div class="container-fluid">

    <div class="navbar-header">
      <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".shrub-skin-strapped-ui-nav">
        <span class="sr-only">Toggle navigation</span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>

      <a class="navbar-brand" href="#"><span data-ng-bind="pageTitle"></span></a>

      <div
        class="mobile navbar-notification"
        data-shrub-ui-notifications
        data-queue-name="shrubExampleGeneral"
      >
      </div>

    </div>

    <div class="navbar-collapse collapse shrub-skin-strapped-ui-nav">

      <div
        class="desktop navbar-notification navbar-right"
        data-shrub-ui-notifications
        data-queue-name="shrubExampleGeneral"
      >
      </div>

      <div
        class="navbar-text navbar-right navbar-user"
      >
        Hi,
        <span
          data-shrub-user-actions
        >
        </span>
      </div>

      <div
        data-shrub-ui-menu
        data-menu="menu"
      ></div>
    </div>
  </div>
</nav>

'''

  ]
```
