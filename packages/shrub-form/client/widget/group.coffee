# # Form - Group
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'shrubAngularDirective', -> [
    '$compile', '$log', 'shrub-form'
    ($compile, $log, formService) ->

      scope: field: '=', form: '='

      link: (scope, element) ->

        scope.$watch 'field', (field) ->

          field.collapse ?= true

        scope.$watchCollection(
          -> scope.field.fields
          (fields) ->

            element.empty()

            for name, field of fields

              # Look up the widget definition and warn if it doesn't exist.
              unless (widget = formService.widgets[field.type])?

                # ###### TODO: Multiline
                $log.warn "Form `#{scope.form.key}` contains a group `#{scope.field.name}` with a non-existent field type `#{field.type}`!"
                continue

              # Default name to the key.
              field.name ?= name

              # Inherit method.
              field.syncModel = scope.field.syncModel

              markup = """

<div
  data-#{widget.directive}
  data-field="field.fields['#{name}']"
  data-form="form"
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

  # #### Implements hook `shrubFormWidgets`.
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
