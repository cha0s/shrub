# UI - Attributes

*Generalized attribute directive.*

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularDirective`.

      registrar.registerHook 'shrubAngularDirective', -> [
        '$compile'
        ($compile) ->

          directive = {}

          directive.link = (scope, element, attr) ->

            updateAttributes = (attributes, oldAttributes) ->
              return unless attributes?

Create a dummy attribute to apply all attributes to, since trying to apply
then directly to the element is potentially problematic.

              dummy = angular.element '<div>'

              for k, v of attributes

                if 'class' is k

###### TODO: We should do a proper _.intersects check here.

                  for class_ in oldAttributes?.class ? []
                    dummy.removeClass class_

                  v = [v] unless angular.isArray v
                  dummy.addClass v.join ' '

                else

                  dummy.attr k, v

Compile and link child directives.

              compileScope = scope.$new true
              compileScope.attributes = attributes
              $compile(dummy)(compileScope)

Set everything that ended up on our dummy element to the parent element.

              dummy.removeClass 'ng-scope'
              attr.$set k, dummy.attr k for k of attributes

            scope.$watch attr['shrubUiAttributes'], updateAttributes, true

          directive

      ]
