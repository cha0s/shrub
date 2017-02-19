# Form - Radio

```coffeescript
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
          field.selectedValue ?= true
          field.model ?= 'field.value'

          field.$change = ($event) -> scope.$$postDigest ->
            field.change field.value, $event

          field.syncModel scope

      template: '''

<div class="radio">

  <label>

    <input
      name="{{field.name}}"
      type="radio"

      data-shrub-ui-attributes="field.attributes"
      data-ng-change="field.$change($event);"
      data-ng-model="field.value"
      data-ng-value="field.selectedValue"
    >

    {{field.label}}

  </label>

</div>

'''

  ]

  assignToElement = (element, value) ->

    element.prop 'checked', true
```

#### Implements hook [`shrubFormWidgets`](../../../../../hooks#shrubformwidgets)

```coffeescript
  registrar.registerHook 'shrubFormWidgets', ->

    widgets = []

    widgets.push

      type: 'radio'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-radio'

    widgets
```
