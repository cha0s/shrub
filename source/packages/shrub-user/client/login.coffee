# User login
```coffeescript
config = require 'config'
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularRoutes`.
```coffeescript
  registrar.registerHook 'shrubAngularRoutes', ->

    routes = []

    routes.push

      path: 'user/login'
      title: 'Sign in'

      controller: [
        '$location', '$scope', 'shrub-ui/messages', 'shrub-user'
        ($location, $scope, messages, user) ->
```
#### Invoke hook `shrubUserLoginStrategies`.
```coffeescript
          strategies = pkgman.invoke 'shrubUserLoginStrategies'
```
#### Invoke hook `shrubUserLoginStrategiesAlter`.
```coffeescript
          pkgman.invoke 'shrubUserLoginStrategiesAlter', strategies
```
Count the active strategies.
```coffeescript
          strategiesCount = pkgman.packagesImplementing(
            'shrubUserLoginStrategies'
          ).length
```
Build the login form.
```coffeescript
          $scope.form =

            key: 'shrub-user-login'

            submits: [

              (values) ->
```
Extract the values from the active strategy's fieldgroup.
```coffeescript
                methodValues = values[values.method]
```
Manually inject the method into the strategy values.
```coffeescript
                methodValues.method = values.method
```
Attempt the login.
```coffeescript
                user.login(methodValues).then ->
```
Notify user.
```coffeescript
                  messages.add(
                    class: 'alert-success'
                    text: 'Logged in successfully.'
                  )
```
Redirect to root.
```coffeescript
                  $location.path '/'

            ]
```
No strategies? Bail.
```coffeescript
          return $location.path '/' if strategiesCount is 0
```
DRY
```coffeescript
          fields = $scope.form.fields = {}
```
If there's only one strategy active, simply inject the `method`
into the form as a hidden field.
```coffeescript
          if strategiesCount is 1

            method = packageName for packageName, strategy of strategies

            fields.method =
              type: 'hidden'
              value: method
```
If there's more than one method, use a dropdown to select the
login strategy.

###### TODO: This is janky from UX perspective. Rely on skin? At least hide inactive strategies' fieldgroups...
```coffeescript
          else

            fields.method =
              type: 'select'
              label: 'Method'
              options: 'key as value for (key , value) in field.methodOptions'
```
Build the options list.
```coffeescript
            fields.method.methodOptions = {}
            for packageName, {methodLabel} of strategies
```
Start the select with the first value, otherwise Angular
will inject a blank element.
```coffeescript
              fields.method.value = packageName unless fields.method.value?
```
Use the strategy labels.
```coffeescript
              fields.method.methodOptions[packageName] = methodLabel
```
Inject a fieldgroup for every login strategy.
```coffeescript
          fields[packageName] = {
            type: 'group'
            collapse: false
            fields: strategy.fields
          } for packageName, strategy of strategies

      ]

      template: '''

<div
  data-shrub-form
  data-form="form"
></div>

'''

    return routes
```
