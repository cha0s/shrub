# Form - Submit

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    ->

      scope: field: '=', form: '='

      link: (scope) ->

        scope.clicked = -> scope.form.$submitted = scope.field

        scope.$watch 'field', (field) ->

          field.value ?= 'Submit'

      template: '''

<input
  class="btn btn-default"
  name="{{field.name}}"
  type="submit"

  data-shrub-ui-attributes="field.attributes"
  data-ng-click="clicked();"
  data-ng-value="field.value"
>

'''

  ]

  assignToElement = (element, value) -> element.val value
```

#### Implements hook [`shrubFormWidgets`](../../../../../hooks#shrubformwidgets)

```coffeescript
  registrar.registerHook 'shrubFormWidgets', ->

    widgets = []

    widgets.push

      type: 'submit'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-submit'

    widgets
```
