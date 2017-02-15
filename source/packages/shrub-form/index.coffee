# Form processing

*Handle form and method parsing, and submission of POST'ed data into the
Angular sandbox.*
```coffeescript
bodyParser = require 'body-parser'
methodOverride = require 'method-override'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularSandboxNavigationMiddleware`.

If the client made a POST request, inject that request into the Angular
sandbox and let it do its thing.
```coffeescript
  registrar.registerHook 'shrubAngularSandboxNavigationMiddleware', ->

    label: 'Handle form submission'
    middleware: [

      (req, next) ->

        {body, sandbox} = req
```
Make sure there's a formKey in the submission.

###### TODO: CRSF check needed here.
```coffeescript
        return next() unless body.formKey?
```
Lookup the cached form.
```coffeescript
        formService = null

        sandbox.inject [
          'shrub-form'
          (form) -> formService = form
        ]

        return next() unless (formCache = formService.forms[body.formKey])?

        {element, scope} = formCache
        widgets = formService.widgets

        form = scope.form
        for k, v of body
          continue if 'formKey' is k

          element = element.find "[name='#{k}']"

          formService.widgets[form.fields[k].type].assignToElement(
            element
            v
          )

          element.trigger 'change'
```
Submit the form into Angular.
```coffeescript
        scope.$digest()
        scope.$apply ->
          scope.$shrubSubmit[body.formKey]().finally -> next()

    ]
```
#### Implements hook `shrubHttpMiddleware`.

Parse POST submissions, and allow arbitrary method form attribute.
```coffeescript
  registrar.registerHook 'shrubHttpMiddleware', (http) ->

    express = require 'express'

    label: 'Parse form submissions'
    middleware: [
      bodyParser.urlencoded extended: true
      methodOverride()
    ]
```
