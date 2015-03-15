# Form - Select

    _ = require 'lodash'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularDirective`.

      registrar.registerHook 'shrubAngularDirective', -> [
        ->

          scope: field: '=', form: '='

          template: '''

    <label
      data-ng-bind="field.label"
    ></label>

    <select
      class="form-control"
      name="{{field.name}}"

      data-shrub-ui-attributes="field.attributes"
      data-ng-model="field.value"
      data-ng-required="field.required"
      data-ng-options="field.options"
    ></select>

    '''

      ]

      assignToElement = (element, value) ->

        element.find("option[value=\"#{value}\"]").prop 'selected', true

#### Implements hook `shrubFormWidgets`.

      registrar.registerHook 'shrubFormWidgets', ->

        widgets = []

        widgets.push

          type: 'select'
          assignToElement: assignToElement
          directive: 'shrub-form-widget-select'

        widgets
