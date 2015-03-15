# Form - Hidden element

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularDirective`.

      registrar.registerHook 'shrubAngularDirective', -> [
        ->

          scope: field: '=', form: '='

          template: '''

    <input
      name="{{field.name}}"
      type="hidden"
      value="{{field.value}}"

      data-shrub-ui-attributes="field.attributes"
    >

    '''

      ]

      assignToElement = (element, value) -> element.attr 'value', value

#### Implements hook `shrubFormWidgets`.

      registrar.registerHook 'shrubFormWidgets', ->

        widgets = []

        widgets.push

          type: 'hidden'
          assignToElement: assignToElement
          directive: 'shrub-form-widget-hidden'

        widgets
