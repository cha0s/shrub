# Skinning

*Implement the skin system, allowing clients to change the look and feel of
the site on-the-fly, as well as quickly load assets from the default skin on
page load.*
```coffeescript
config = require 'config'
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubAngularDirectiveAlter`.
```coffeescript
  registrar.registerHook 'shrubAngularDirectiveAlter', (directive, path) -> [

    '$cacheFactory', '$compile', '$http', '$injector', '$interpolate', '$q', '$rootScope'
    ($cacheFactory, $compile, $http, $injector, $interpolate, $q, $rootScope) ->
```
Ensure ID is a candidate.
```coffeescript
      directive.candidateKeys ?= []
      directive.candidateKeys.unshift 'id'

      currentSkinKey = null
      defaultSkinKey = config.get 'packageConfig:shrub-skin:default'
```
Proxy link function to add our own directive retrieval and compilation
step.
```coffeescript
      link = directive.link
      directive.link = (scope, element, attr, controller, transclude) ->

        candidateHooksInvoked = {}
```
Save top-level arguments for later calls to link functions.
```coffeescript
        topLevelArgs = arguments
```
Current template candidate.
```coffeescript
        candidate = undefined

        recalculateCandidate = ->
```
Get the skin assets.
```coffeescript
          skinAssets = config.get(
            "packageConfig:shrub-skin:assets:#{currentSkinKey}"
          )
```
Track changes to the current template candidate.
```coffeescript
          oldCandidate = candidate
```
Build a list of all candidates by first attempting to interpolate
candidate keys, and falling back to attribute values, if any.
Candidate arrays are joined by single dashes.
```coffeescript
          candidateList = do ->
            list = []

            for keys in directive.candidateKeys
              keys = [keys] unless angular.isArray keys

              item = []
              for key in keys

                specific = scope[key]
                specific = attr[key] unless specific

                item.push specific if specific

              item = item.join '-'
              list.push item if item

            list
```
Map the candidate list to template filenames and add the base path
template candidate.
```coffeescript
          candidateTemplates = for candidate_ in candidateList
            "#{path}--#{candidate_}.html"
          candidateTemplates.push "#{path}.html"
```
Return the first existing template. The asset templates are
already sorted by descending specificity.
```coffeescript
          candidate = do ->
            for uri in candidateTemplates
              return uri if skinAssets?.templates?[uri]

            return null
```
If the candidate changed, clear the hook invocation cache and
relink.
```coffeescript
          if candidate isnt oldCandidate
            candidateHooksInvoked = {}
```
Insert and compile the template HTML if it exists.
```coffeescript
            if skinAssets?.templates?[candidate]
```
Insert and compile HTML.
```coffeescript
              element.html skinAssets.templates[candidate]
              $compile(element.contents())(scope)
```
Call directive link function.
```coffeescript
            link topLevelArgs... if link?
```
Invoke the candidate link hooks.
```coffeescript
          invocations = [
            'shrubSkinLink'
            "shrubSkinLink--#{directive.name}"
          ]
```
Add the candidates in reverse order, so they ascend in
specificity.
```coffeescript
          invocations.push(
            "shrubSkinLink--#{directive.name}--#{c}"
          ) for c in candidateList.reverse()

          for hook in invocations
            continue if candidateHooksInvoked[hook]
            candidateHooksInvoked[hook] = true
```
#### Invoke hook `shrubSkinLink`.

#### Invoke hook `shrubSkinLink--DIRECTIVE`.

#### Invoke hook `shrubSkinLink--DIRECTIVE--ID`.
```coffeescript
            for f in pkgman.invokeFlat hook

              $injector.invoke(
                f, null
                $directive: directive
                $scope: scope
                $element: element
                $attr: attr
                $controller: controller
                $transclude: transclude
              )

        applySkin = (skinKey) ->
          currentSkinKey = skinKey
          recalculateCandidate()

        applySkin defaultSkinKey
```
Relink again every time the skin changes.
```coffeescript
        $rootScope.$on 'shrub-skin.changed', (event, skinKey) ->
          candidateHooksInvoked = {}
          applySkin skinKey
```
Set watches for all candidate-related values.
```coffeescript
        keysSeen = {}
        watchers = []
        for keys in directive.candidateKeys

          keys = [keys] unless angular.isArray keys
          for key in keys
            continue if keysSeen[key]
            keysSeen[key] = true

            attr.$observe key, recalculateCandidate
            watchers.push -> scope[attr[key]]

        scope.$watchGroup watchers, recalculateCandidate

  ]
```
#### Implements hook `shrubAngularProvider`.
```coffeescript
  registrar.registerHook 'shrubAngularProvider', -> [

    '$injector', '$provide'
    ($injector, $provide) ->

      provider = {}

      provider.$get = [
        '$http', '$interval', '$q', '$rootScope', '$window'
        ($http, $interval, $q, $rootScope, $window) ->

          service = {}
```
## skin.addStylesheet

(String) `href` - The href of the stylesheet to add. *Add a skin
stylesheet.*
```coffeescript
          service.addStylesheet = (href) ->

            deferred = $q.defer()

            styleSheets = $window.document.styleSheets
            index = styleSheets.length
```
Insert the stylesheed as a link element in the head element,
classed with 'skin' so we can easily remove it if the skin
changes.
```coffeescript
            element = $window.document.createElement 'link'
            element.type = 'text/css'
            element.rel = 'stylesheet'
            element.href = "/skin/shrub-skin-strapped/#{href}"
            element.className = 'skin'
            angular.element('head').append element

            resolve = -> deferred.resolve()
```
A rare case where IE actually does the right thing! (and Opera).
```coffeescript
            if $window.opera or ~$window.navigator.userAgent.indexOf 'MSIE'

              element.onload = resolve
              element.onreadystatechange = ->
                switch @readyState
                  when 'loaded', 'complete'
                    resolve()
```
Everyone else needs to resort to polling.
```coffeescript
            else

              wasParsed = ->

                try

                  styleSheet = styleSheets[index]

                  return true if styleSheet.cssRules
                  return true if styleSheet.rules?.length

                  return false

                catch error

                  return false

              poll = $interval ->

                if wasParsed()

                  $interval.cancel poll
                  resolve()

                return

              , 10

            deferred.promise
```
## skin.addStylesheets

(String Array) `hrefs` - The hrefs of the stylesheets to add. *Add
a list of skin stylesheets.*
```coffeescript
          service.addStylesheets = (hrefs) ->
            $q.all (service.addStylesheet href for href in hrefs)
```
CLoak the body during the skin transition.
```coffeescript
          addBodyCloak = ->

            $body = angular.element 'body'
            $body.addClass 'shrub-skin-cloak'
```
Remove the cloak after the transition is complete.
```coffeescript
          removeBodyCloak = ->

            $body = angular.element 'body'
            $body.removeClass 'shrub-skin-cloak'
```
Remove all current skin stylesheets.
```coffeescript
          removeSkinStylesheets = ->

            $head = angular.element 'head'
            head = $head[0]

            node = head.firstChild
            while node

              nextNode = node.nextSibling

              if 'LINK' is node.tagName
                if angular.element(node).hasClass 'skin'
                  head.removeChild node

              node = nextNode

            return
```
Use the correct assets for the environment.
```coffeescript
          environmentKey = if 'production' is cache.get 'environment'
            'production'
          else
            'default'
```
## skin.change

(String) `skinKey` - The key of the skin to change to *Change
skin.*

###### TODO: Need to track current, this should be a nop in that case.
```coffeescript
          service.change = (skinKey) ->
```
Cloak the body.
```coffeescript
            addBodyCloak()
            removeSkinStylesheets()

            skinAssets = config.get(
              "packageConfig:shrub-skin:assets:#{skinKey}"
            )
```
Uncloak and notify when finished.
```coffeescript
            service.addStylesheets(
              skinAssets.styleSheets[environmentKey]
            ).finally ->
              removeBodyCloak()

              $rootScope.$broadcast 'shrub-skin.changed', skinKey

          service

      ]

      provider

  ]
```
