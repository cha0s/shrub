# Form processing

*Define a directive for Angular forms, and a service to cache and look them
up later.*

```coffeescript
_ = require 'lodash'
i8n = require 'inflection'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`shrubAngularDirective`](../../../hooks#shrubangulardirective)

```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [
    '$compile', '$exceptionHandler', '$injector', '$log', '$q', 'shrub-form', 'shrub-require'
    ($compile, $exceptionHandler, $injector, $log, $q, formService, require) ->

      link: (scope, element, attrs) ->
```

Keep a reference to the form scope, if the form attribute value
changes, it'll need to be rebuilt.

```coffeescript
        formScope = null
        scope.$watch attrs.form, (form) ->
          return unless form?

          form.key ?= attrs.form
```

Get the form's current values.

```coffeescript
          form.values = ->
            values = {}

            for name, field of form.fields
              widget = formService.widgets[field.type]
              if widget.extractValues?
                widget.extractValues field, values, formService
              else
                values[field.name] = field.value

            return values
```

Normalize form submits into an array.

```coffeescript
          form.submits = [form.submits] unless angular.isArray form.submits
```

Build a submit function which will be bound to ngSubmit.

```coffeescript
          (scope['$shrubSubmit'] ?= {})[form.key] = ($event) ->
```

Call all the form submission handlers.

```coffeescript
            try

              values = form.values()

              promises = for submit in form.submits
                submit values, form, $event

              $q.all promises

            catch error
              $exceptionHandler error
```

#### Invoke hook [`shrubFormAlter`](../../../hooks#shrubformalter)

```coffeescript
          pkgman.invokeFlat 'shrubFormAlter', form
```

#### Invoke hook [`shrubFormFormKeyAlter`](../../../hooks#shrubformformkeyalter)

```coffeescript
          pkgman.invokeFlat "shrubForm#{
            pkgman.normalizePath form.key, true
          }Alter", form
```

Create the form element.

```coffeescript
          $form = angular.element '<form />'
          $form.addClass form.key
```

Default method to POST.

```coffeescript
          $form.attr 'method', attrs.method ? 'POST'
          $form.attr 'data-ng-submit', "$shrubSubmit['#{form.key}']($event)"
```

Build the form fields.

```coffeescript
          for name, field of form.fields
```

Look up the widget definition and warn if it doesn't exist.

```coffeescript
            unless (widget = formService.widgets[field.type])?

              $log.warn "Form `#{
                form.key
              }` contains non-existent field type `#{
                field.type
              }`!"
              continue
```

Default name to the key.

```coffeescript
            field.name ?= name
```

Helper function to synchronize the field and model value.

```coffeescript
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
```

Add hidden form key to allow server-side interception/processing.

```coffeescript
          $formKeyElement = angular.element '<input type="hidden" />'
          $formKeyElement.attr name: 'formKey', value: form.key
          $form.append $formKeyElement
```

Remove any old stuff.

```coffeescript
          if formScope
            formScope.$destroy()
            element.find('form').remove()
```

Insert and compile the form element.

```coffeescript
          element.append $form
          $compile($form) formScope = scope.$new()
```

Register the form in the system.

```coffeescript
          formService.cache form.key, formScope, $form

  ]
```

#### Implements hook [`shrubAngularService`](../../../hooks#shrubangularservice)

```coffeescript
  registrar.registerHook 'shrubAngularService', -> [

    ->

      service = forms: {}, widgets: {}
```

## form.cache

* (string) `key` - The form key.

* (Scope) `scope` - The form's Angular scope.

* (Element) `element` - The form's jqLite element.

*Cache a form for later lookup.*

```coffeescript
      service.cache = (key, scope, element) ->
        service.forms[key] = scope: scope, element: element
```

#### Invoke hook [`shrubFormWidgets`](../../../hooks#shrubformwidgets)

```coffeescript
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
```
