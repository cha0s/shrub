# Form - checkbox

    _ = require 'lodash'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `directive`.

      registrar.registerHook 'directive', -> [
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

#### Implements hook `formWidgets`.

      registrar.registerHook 'formWidgets', ->

        widgets = []

        widgets.push

          type: 'checkbox'
          assignToElement: assignToElement
          directive: 'shrub-form-widget-checkbox'

        widgets
