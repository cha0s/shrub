# Form - Text

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

          field.minLength ?= 0
          field.maxLength ?= Infinity
          field.pattern ?= /.*/
          field.model ?= 'field.value'

          field.syncModel scope

      template: '''

<label
  data-ng-if="!!field.label"
  data-ng-bind="field.label"
></label>

<input
  class="form-control"
  name="{{field.name}}"
  type="{{field.type}}"

  data-shrub-ui-attributes="field.attributes"
  data-ng-model="field.value"
  data-ng-required="field.required"
  data-ng-minlength="{{field.minlength}}"
  data-ng-maxlength="{{field.maxlength}}"
  data-ng-pattern="field.pattern"
  data-ng-trim="{{field.trim}}"
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

      type: 'email'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-text'

    widgets.push

      type: 'password'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-text'

    widgets.push

      type: 'text'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-text'

    widgets
```
