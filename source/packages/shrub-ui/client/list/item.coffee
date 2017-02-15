# UI - list item
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularController`.
```coffeescript
  registrar.registerHook 'shrubAngularController', -> [

    class ListItemController

      link: (scope, element, attr) ->

        scope.$watch(
          -> scope.item?.markup
          ->

            for child in element.children()
```
Child list?
```coffeescript
              $child = angular.element child
              continue if $child.attr('data-shrub-ui-list')?

              $child.remove()

            element.prepend scope.item.markup if scope.item?.markup

        )

  ]
```
#### Implements hook `shrubAngularDirective`.
```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [

    ->

      directive = {}

      directive.bindToController = true

      directive.candidateKeys = [
        'ancestorPath'
      ]

      directive.scope =

        item: '='
        ancestorPath: '=?'

      directive.template = '''

<ul
  data-ng-if="item.list"
  data-shrub-ui-list
  data-shrub-ui-attributes="item.list.attributes"
  data-list="item.list"
  data-parent-ancestor-path="ancestorPath"
></ul>

'''

      directive

  ]
```
