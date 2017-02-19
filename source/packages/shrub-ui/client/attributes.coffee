# UI - Attributes

*Generalized attribute directive.*

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    '$compile'
    ($compile) ->

      directive = {}

      directive.link = (scope, element, attr) ->

        updateAttributes = (attributes, oldAttributes) ->
          return unless attributes?
```

Create a dummy attribute to apply all attributes to, since trying
to apply then directly to the element is potentially problematic.

```coffeescript
          dummy = angular.element '<div>'

          for k, v of attributes

            if 'class' is k

              v = [v] unless angular.isArray v
              dummy.addClass v.join ' '

            else

              dummy.attr k, v
```

Compile and link child directives.

```coffeescript
          compileScope = scope.$new true
          compileScope.attributes = attributes
          $compile(dummy)(compileScope)
```

Set everything that ended up on our dummy element to the parent
element.

```coffeescript
          dummy.removeClass 'ng-scope'
          attr.$set k, dummy.attr k for k of attributes

        scope.$watch attr['shrubUiAttributes'], updateAttributes, true

      directive

  ]
```
