# # Form processing
#
# *Define a directive for Angular forms, and a service to cache and look them
# up later.*
_ = require 'lodash'
i8n = require 'inflection'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubAngularDirective`.
  registrar.registerHook 'shrubAngularDirective', -> [
    '$compile', '$exceptionHandler', '$injector', '$log', '$q', 'shrub-form', 'shrub-require'
    ($compile, $exceptionHandler, $injector, $log, $q, formService, require) ->

      link: (scope, element, attrs) ->

        # Keep a reference to the form scope, if the form attribute value
        # changes, it'll need to be rebuilt.
        #
        # ###### TODO: It shouldn't be trashed as it is now, it should be
        # moved over to a new scope non-destructively.
        formScope = null
        scope.$watch attrs.form, (form) ->
          return unless form?

          form.key ?= attrs.form

          # Get the form's current values.
          form.values = ->
            values = {}

            for name, field of form.fields
              widget = formService.widgets[field.type]
              if widget.extractValues?
                widget.extractValues field, values, formService
              else
                values[field.name] = field.value

            return values

          # Normalize form submits into an array.
          form.submits = [form.submits] unless angular.isArray form.submits

          # Build a submit function which will be bound to ngSubmit.
          (scope['$shrubSubmit'] ?= {})[form.key] = ($event) ->

            # Call all the form submission handlers.
            try

              values = form.values()

              promises = for submit in form.submits
                submit values, form, $event

              $q.all promises

            catch error
              $exceptionHandler error

          # #### Invoke hook `shrubFormAlter`.
          pkgman.invokeFlat 'shrubFormAlter', form

          # #### Invoke hook `shrubFormFormKeyAlter`.
          #
          # ###### TODO: Multiline
          pkgman.invokeFlat "shrubForm#{pkgman.normalizePath form.key, true}Alter", form

          # Create the form element.
          $form = angular.element '<form />'
          $form.addClass form.key

          # Default method to POST.
          $form.attr 'method', attrs.method ? 'POST'
          $form.attr 'data-ng-submit', "$shrubSubmit['#{form.key}']($event)"

          # Build the form fields.
          for name, field of form.fields

            # Look up the widget definition and warn if it doesn't exist.
            unless (widget = formService.widgets[field.type])?

              # ###### TODO: Multiline
              $log.warn "Form `#{form.key}` contains non-existent field type `#{field.type}`!"
              continue

            # Default name to the key.
            field.name ?= name

            # Helper function to synchronize the field and model value.
            do (field) -> field.syncModel = (scope) ->
              self = this

              return unless self.model?

              self.$modelDereg?()
              self.$modelDereg = null

              self.$valueDereg?()
              self.$valueDereg = null

              if self.model isnt 'field.value'

                self.$valueDereg = scope.$watch 'field.value', (value) ->
                  scope.$eval "#{self.model} = value", value: value

                self.$modelDereg = scope.$watch self.model, (value) ->
                  self.value = value

              return

            $form.append """

<div
  data-#{widget.directive}
  data-field="#{attrs.form}.fields['#{name}']"
  data-form="#{attrs.form}"
></div><span> </span>

"""

          # Add hidden form key to allow server-side interception/processing.
          $formKeyElement = angular.element '<input type="hidden" />'
          $formKeyElement.attr name: 'formKey', value: form.key
          $form.append $formKeyElement

          # Remove any old stuff.
          if formScope
            formScope.$destroy()
            element.find('form').remove()

          # Insert and compile the form element.
          element.append $form
          $compile($form) formScope = scope.$new()

          # Register the form in the system.
          formService.cache form.key, formScope, $form

  ]

  # #### Implements hook `shrubAngularService`.
  registrar.registerHook 'shrubAngularService', -> [

    ->

      service = forms: {}, widgets: {}

      # ## form.cache
      #
      # * (string) `key` - The form key.
      #
      # * (Scope) `scope` - The form's Angular scope.
      #
      # * (Element) `element` - The form's jqLite element.
      #
      # *Cache a form for later lookup.*
      service.cache = (key, scope, element) ->
        service.forms[key] = scope: scope, element: element

      # #### Invoke hook `shrubFormWidgets`.
      for formWidgets in pkgman.invokeFlat 'shrubFormWidgets'
        formWidgets = [formWidgets] unless _.isArray formWidgets

        for formWidget in formWidgets
          continue unless formWidget.directive?
          service.widgets[formWidget.type] = formWidget

      service

  ]

  registrar.recur [
    'widget/checkbox'
    'widget/checkboxes'
    'widget/group'
    'widget/hidden'
    'widget/markup'
    'widget/radio'
    'widget/radios'
    'widget/submit'
    'widget/select'
    'widget/text'
    'widget/textarea'
  ]