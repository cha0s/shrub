# Form - checkbox

    _ = require 'lodash'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularDirective`.

      registrar.registerHook 'shrubAngularDirective', -> [
        ->

          scope: field: '=?'

          template: '''

    <div class="checkbox">

      <label>

        <input
          name="{{field.name}}"
          type="checkbox"

          data-ng-model="field.value"
        >

        {{field.label}}

      </label>

    </div>

    '''

      ]

      assignToElement = (element, value) -> element.prop 'checked', 'on' is value

#### Implements hook `shrubFormWidgets`.

      registrar.registerHook 'shrubFormWidgets', ->

        widgets = []

        widgets.push

          type: 'checkbox'
          assignToElement: assignToElement
          directive: 'shrub-form-widget-checkbox'

        widgets
