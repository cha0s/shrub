# UI - List
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularController`.
```coffeescript
  registrar.registerHook 'shrubAngularController', -> [

    class ListController

      link: (scope, element, attr) ->
```
Maintain the full ancestor path for list and item.
```coffeescript
        scope.$watchGroup(
          [
            -> scope.list?.name
            -> scope.parentAncestorPath
          ]
          ->
```
Keep track of the full ancestor path.
```coffeescript
            parts = []
            parts.push scope.parentAncestorPath if scope.parentAncestorPath
            parts.push scope.list.name if scope.list?.name
            scope.ancestorPath = parts.join '-'

            element.addClass scope.list.name if scope.list?.name
        )

  ]
```
#### Implements hook `shrubAngularDirective`.
```coffeescript
  registrar.registerHook 'shrubAngularDirective', -> [

    '$compile', '$timeout'
    ($compile, $timeout) ->

      directive = {}

      directive.bindToController = true

      directive.candidateKeys = [
        'list.attributes.id'
        'list.name'
        'ancestorPath'
      ]
```
Prevent infinite recursion when compiling nested lists.
```coffeescript
      directive.compile = (cElement) ->

        contents = cElement.contents().remove()

        (scope, lElement, attr, controller) ->

          compiled = $compile contents
          lElement.append compiled scope

          directive.link arguments...

      directive.scope =

        list: '='
        parentAncestorPath: '=?'

      directive.template = '''

<li
  data-ng-repeat="item in list.items"

  data-shrub-ui-list-item
  data-shrub-ui-attributes="item.attributes"
  data-item="item"
  data-parent-ancestor-path="parentAncestorPath"
></li>

'''

      directive

  ]

  registrar.recur [
    'item'
  ]
```
