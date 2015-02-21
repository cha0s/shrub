# UI - Menu

*Manage menus; essentially recursive lists with an emphasis on navigation.*

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `controller`.

      registrar.registerHook 'controller', -> [
        '$compile', '$location', '$scope'
        class MenuController

## *constructor*

          constructor: ($compile, $location, $scope) ->
            self = this

            self.linkMap = {}

            $scope.$watch(
              -> $scope.menu
              -> self.rebuildListTree $compile, $scope if $scope.menu?
              true
            )

            $scope.$watchGroup(
              [
                -> $location.path()
                -> self.linkMap
              ]
              (newValues, oldValues) ->

Paths without the leading slash.

                if oldPath = oldValues[0]
                  oldPath = oldPath.substr 1

Remove the active class if we navigated away.

                  if self.linkMap[oldPath]?[0].attributes?.class?
                    attributes = self.linkMap[oldPath][0].attributes
                    if attributes.class.length
                      index = attributes.class.indexOf 'active'
                      attributes.class.splice index, 1

Add the active class if we navigated to.

                newPath = newValues[0].substr 1
                if self.linkMap[newPath]?
                  attributes = self.linkMap[newPath][0].attributes
                  (attributes.class ?= []).push 'active'

            )

## MenuController#rebuildListTree

*Rebuild the list tree from the menu tree.*

          rebuildListTree: ($compile, $scope) ->
            self = this

            rebuildBranch = (list, branch) ->

              list.attributes ?= {}

              buildItem = (leaf) ->

                item = angular.copy leaf
                item.attributes ?= {}
                item.markup = []

                if leaf.markupBefore?
                  item.markup.push angular.element leaf.markupBefore

                item.markup.push linkElement = angular.element '<a>'
                linkElement.attr 'data-shrub-ui-attributes', 'attributes'
                linkElement.attr 'href', leaf.path
                linkElement.html leaf.label

                compileScope = $scope.$new true
                compileScope.attributes = leaf.linkAttributes

                $compile(linkElement)(compileScope)

                linkElement.removeAttr 'data-shrub-ui-attributes'

                if leaf.markupAfter?
                  item.markup.push angular.element leaf.markupAfter

                (self.linkMap[leaf.path] ?= []).push item

Recur.

                if leaf.list?

                  item.list = angular.copy leaf.list
                  rebuildBranch item.list, leaf.list

                item

              list.items = for leaf in branch.items
                buildItem leaf

              return

            self.linkMap = {}
            $scope.list = angular.copy $scope.menu
            rebuildBranch $scope.list, $scope.menu

      ]

#### Implements hook `directive`.

      registrar.registerHook 'directive', -> [

        '$compile', '$timeout'
        ($compile, $timeout) ->

          directive = {}

          directive.bindToController = true

          directive.candidateKeys = [
            'menu.name'
          ]

          directive.scope =

            menu: '='

          directive.template = '''

    <ul
      data-shrub-ui-list
      data-shrub-ui-attributes="list.attributes"
      data-list="list"
    ></ul>

    '''

          directive

      ]
