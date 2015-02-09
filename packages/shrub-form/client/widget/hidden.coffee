
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `directive`
  registrar.registerHook 'directive', -> [
    ->

      scope: field: '=?'

      template: '''

<input
  name="{{field.name}}"
  type="hidden"
  value="{{field.value}}"
>

'''

  ]

  assignToElement = (element, value) -> element.attr 'value', value

  # ## Implements hook `formWidgets`
  registrar.registerHook 'formWidgets', ->

    widgets = []

    widgets.push

      type: 'hidden'
      assignToElement: assignToElement
      directive: 'shrub-form-widget-hidden'

    widgets
