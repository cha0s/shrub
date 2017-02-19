# Form - checkbox

```coffeescript
_ = require 'lodash'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    ->

      scope: field: '=', form: '='

      link: (scope) ->

        scope.$watch 'field', (field) ->

          field.change ?= ->
          field.model ?= 'field.value'

          field.$change = ($event) -> scope.$$postDigest ->
            field.change field.value, $event

          field.syncModel scope

      template: '''

<div class="checkbox">

  <label>

    <input
      name="{{field.name}}"
      type="checkbox"

      data-shrub-ui-attributes="field.attributes"
      data-ng-change="field.$change($event);"
      data-ng-true-value="{{field.trueValue || true}}"
      data-ng-false-value="{{field.falseValue || false}}"
      data-ng-model="field.value"
    >

    {{field.label}}

  </label>

</div>

'''

  ]

  assignToElement = (element, value) -> element.prop 'checked', 'on' is value
```

#### Implements hook [`shrubFormWidgets`](../../../../../hooks#shrubformwidgets)

```coffeescript
  registrar.registerHook 'shrubFormWidgets', ->

    widgets = []

    widgets.push

      type: 'checkbox'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-checkbox'

    widgets
```
