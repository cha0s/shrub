# Form - Group

```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    '$compile', '$log', 'shrub-form'
    ($compile, $log, formService) ->

      scope: field: '=', form: '='

      link: (scope, element) ->

        scope.$watch 'field', (field) ->

          field.collapse ?= true
          field.isVisible ?= -> true

        scope.$watchCollection(
          -> scope.field.fields
          (fields) ->

            element.empty()

            for name, field of fields
```

Look up the widget definition and warn if it doesn't exist.

```coffeescript
              unless (widget = formService.widgets[field.type])?

                $log.warn "Form `#{
                  scope.form.key
                }` contains a group `#{
                  scope.field.name
                }` with a non-existent field type `#{
                  field.type
                }`!"
                continue
```

Default name to the key.

```coffeescript
              field.name ?= name
```

Inherit method.

```coffeescript
              field.syncModel = scope.field.syncModel

              markup = """

<div
  data-#{widget.directive}
  data-ng-show="field.isVisible()"
  data-field="field.fields['#{name}']"
  data-form="form"
  data-shrub-ui-attributes="field.attributes"
></div><span> </span>

"""

              element.append $compile(markup)(scope)

            return

        )

      template: '''
<div
  data-shrub-ui-attributes="field.attributes"
></div>

'''

  ]
```

#### Implements hook [`shrubFormWidgets`](../../../../../hooks#shrubformwidgets)

```coffeescript
  registrar.registerHook 'shrubFormWidgets', ->

    widgets = []

    widgets.push

      type: 'group'
      directive: 'shrub-form-widget-group'
      extractValues: (field, values, formService) ->

        for name, subfield of field.fields
          widget = formService.widgets[subfield.type]
          if widget.extractValues?
            widget.extractValues(
              subfield
              if field.collapse
                values
              else
                values[field.name] ?= {}
              formService
            )
          else
            if field.collapse
              values[subfield.name] = subfield.value
            else
              (values[field.name] ?= {})[subfield.name] = subfield.value

    widgets
```
