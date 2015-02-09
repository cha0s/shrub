
_ = require 'lodash'

exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `directive`
  registrar.registerHook 'directive', -> [
    ->

      scope: field: '=?'

      link: (scope, element) ->

        scope.$watchCollection(
          -> scope.field.radios
          ->

            for radio in scope.field.radios
              radio.name = field.name
              radio.type = 'radio'

            # Sync the radio value with field.value
            $radios = angular.element('.radio input', element)
            $radios.off 'change'
            $radios.on 'change', ->
              field.value = $radios.filter(':checked').val()

            return

        )

      template: '''

<div class="radios">

  <label
    data-ng-bind="field.label"
  ></label>

  <ul>

    <li
      data-ng-class="{first: $first}"
      data-ng-repeat="radio in field.radios"
      data-shrub-form-widget-radio
      data-field="radio"
    ></li>

  </ul>

</div>

'''

  ]

  assignToElement = (element, value) ->

    for k, v of value

      element.find('.radio input[name"' + k + '"]').prop 'checked', true

  # ## Implements hook `formWidgets`
  registrar.registerHook 'formWidgets', ->

    widgets = []

    widgets.push

      type: 'radios'
      directive: 'shrub-form-widget-radios'

    widgets

