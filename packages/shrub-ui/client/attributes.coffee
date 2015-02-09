
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `directive`
  registrar.registerHook 'directive', -> [
    '$compile'
    ($compile) ->

      directive = {}

      directive.link = (scope, element, attr) ->

        updateAttributes = (attributes, oldAttributes) ->
          return unless attributes?

          dummy = angular.element '<div>'

          for k, v of attributes

            if 'class' is k

              for class_ in oldAttributes?.class ? []
                dummy.removeClass class_

              v = [v] unless angular.isArray v
              dummy.addClass v.join ' '

            else

              dummy.attr k, v

          compileScope = scope.$new true
          compileScope.attributes = attributes

          $compile(dummy)(compileScope)

          dummy.removeClass 'ng-scope'

          attr.$set k, dummy.attr k for k of attributes

        scope.$watch attr['shrubUiAttributes'], updateAttributes, true

      directive

  ]
