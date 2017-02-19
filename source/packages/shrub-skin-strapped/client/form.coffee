# Strapped - Notifications

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubSkinLink`](../../../../hooks#shrubskinlink)

```coffeescript
  registrar.registerHook 'shrubSkinLink', -> [
    '$directive', '$element'
    (directive, element) ->

      return unless ~[
        'shrubFormWidgetSubmit'
        'shrubFormWidgetText'
        'shrubFormWidgetCheckbox'
        'shrubFormWidgetRadio'
      ].indexOf directive.name

      element.addClass 'form-group'
  ]
```

#### Implements hook [`shrubSkinLink--DIRECTIVE`](../../../../hooks#shrubskinlink--directive)

```coffeescript
  registrar.registerHook 'shrubSkinLink--shrubFormWidgetGroup', -> [
    '$element'
    (element) -> element.addClass 'form-inline'
  ]
```
