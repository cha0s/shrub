# # Strapped - Notifications
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubSkinLink`.
  registrar.registerHook 'shrubSkinLink', -> [
    '$directive', '$element'
    (directive, element) ->

      return unless ~[
        'shrubFormWidgetSubmit'
        'shrubFormWidgetText'
        'shrubFormWidgetCheckbox'
        'shrubFormWidgetRadio'
      ].indexOf directive.name

      element.addClass 'form-group'
  ]

  # #### Implements hook `shrubSkinLink--DIRECTIVE`.
  registrar.registerHook 'shrubSkinLink--shrubFormWidgetGroup', -> [
    '$element'
    (element) -> element.addClass 'form-inline'
  ]

