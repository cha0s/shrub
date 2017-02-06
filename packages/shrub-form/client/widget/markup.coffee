# # Form - Markup
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'shrubAngularDirective', -> [
    '$compile'
    ($compile) ->

      scope: field: '=', form: '='

      link: (scope, element) ->

        scope.$watch 'field', (field) ->

          field.model ?= 'field.value'

          field.syncModel scope

        scope.$watch 'field.value', (markup) ->

          $container = element.find 'div'
          $container.empty().append $compile(markup)(scope)

      template: '''

<div
  class="markup"

  data-shrub-ui-attributes="field.attributes"
></div>

'''

  ]

  # #### Implements hook `shrubFormWidgets`.
  registrar.registerHook 'shrubFormWidgets', ->

    widgets = []

    widgets.push

      type: 'markup'
      assignToElement: ->
      directive: 'shrub-form-widget-markup'

    widgets