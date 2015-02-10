
# Package management for Angular

*This is where shrub's package system meets Angular's module system. Packages'
implementations of controllers, services, filters, providers, and directives
are gathered and registered into Angular.*

    angular.module('shrub.packages', [
      'shrub.require'
      'shrub.pkgman'
    ])

      .config([
        '$compileProvider', '$controllerProvider', '$filterProvider'
        '$injector', '$provide', 'shrub-pkgmanProvider'
        'shrub-requireProvider'
        (
          $compileProvider, $controllerProvider, $filterProvider
          $injector, $provide, pkgman, {require}
        ) ->

          config = require 'config'
          debug = require('debug') 'shrub:angular'

Set an injector so that Angular injection can occur out of band.

          angular_ = require 'angular'
          angular_.setInjector $injector

## Invoke hook `controller`.

Allows packages to define Angular controllers. Implementations should return an
[annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).

          debug 'Registering controllers...'

          for path, injected of pkgman.invoke 'controller'
            controllerName = pkgman.normalizePath path
            debug controllerName
            $controllerProvider.register controllerName, injected

          debug 'Controllers registered.'

          debug 'Registering directives...'

Normalize, augment, and register a directive.

          prepareDirective = (name, path, injected) -> ($injector) ->

Normalize the directive to object form.

            directive = $injector.invoke injected
            directive = link: directive if angular.isFunction directive

Ensure a compilation function exists for the directive which by default
returns the `link` function.

            directive.compile ?= -> directive.link

Proxy any defined link function, firing any attached any controllers' `link`
method, as well as passing execution on to the original `link` function.

            link = directive.link
            directive.link = (scope, element, attrs, controllers) ->
              if controllers?
                controllers = [controllers] unless angular.isArray controllers
                controller.link? arguments... for controller in controllers

              link? arguments...

Ensure the directive has a name. Defaults to the normalized path of the
implementing package.

            directive.name ?= name

If controller binding is specified, the controller defaults to the directive
name. In other words, if you define a directive and a controller in the same
package, and specify `directive.bindToController = true`, your directive will
include the controller automatically.

            if directive.bindToController
              directive.controller ?= directive.name

Handle a bunch of internal Angular normalization.

            directive.require ?= directive.controller and directive.name
            directive.priority ?= 0
            directive.restrict ?= 'EA'

            if angular.isObject directive.scope
              directive.$$isolateBindings = isolateBindingsFor directive

## Invoke hook `augmentDirective`.

Allows packages to augment the directives defined by packages. One example is
the automatic relinking functionality implemented by
[shrub-skin](../packages/shrub-skin/client/index.coffee#L12).

            for injectedDirective in pkgman.invokeFlat(
              'augmentDirective', directive, path
            )
              $injector.invoke injectedDirective

Haven't gone deep enough into Angular to understand why this has to be, but it
does.

            directive.index = 0
            return [directive]

Internal Angular state that we have to reset.

          isolateBindingsFor = (directive) ->

            LOCAL_REGEXP = /^\s*([@&]|=(\*?))(\??)\s*(\w*)\s*$/

            bindings = {}

            for scopeName, definition of directive.scope
              match = definition.match LOCAL_REGEXP

              throw angular.$$minErr('$compile')(
                'iscp'
                "
                  Invalid isolate scope definition for directive '{0}'.
                  Definition: {... {1}: '{2}' ...}
                "
                directive.name, scopeName, definition
              ) unless match

              bindings[scopeName] =
                mode: match[1][0]
                collection: match[2] is '*'
                optional: match[3] is '?'
                attrName: match[4] or scopeName

            return bindings

## Invoke hook `directive`.

Allows packages to define Angular directives. Implementations should return an
[annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).

          for path, injected of pkgman.invoke 'directive'
            do (path, injected) ->
              directiveName = pkgman.normalizePath path
              debug directiveName

First, register it through Angular's normal registration mechanism. This sets
a bunch of internal state we don't have access to.

              $compileProvider.directive directiveName, injected

Follow that by normalizing, augmenting, and registering the directive again.
It will run over the previous definition, ensuring everything works nicely.

              $provide.factory "#{directiveName}Directive", [
                '$injector', prepareDirective directiveName, path, injected
              ]

          debug 'Directives registered.'

          debug 'Registering filters...'

## Invoke hook `filter`.

Allows packages to define Angular filters. Implementations should return a
function.

          for path, injected of pkgman.invoke 'filter'
            filterName = pkgman.normalizePath path
            debug filterName
            $filterProvider.register filterName, injected

          debug 'Filters registered.'

## Invoke hook `provider`.

Allows packages to define Angular providers. Implementations should return an
[annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).

          debug 'Registering providers...'

          for path, provider of pkgman.invoke 'provider'
            debug path
            $provide.provider path, provider

          debug 'Providers registered.'

## Invoke hook `service`.

Allows packages to define Angular services. Implementations should return an
[annotated function](http://docs.angularjs.org/guide/di#dependency-annotation).

          debug 'Registering services...'

          for path, injected of pkgman.invoke 'service'
            debug path
            $provide.service path, injected

          debug 'Services registered.'

      ])

The module that provides Angular with access to Shrub's package manager.

    angular.module('shrub.pkgman', [
      'shrub.require'
    ])

      .provider 'shrub-pkgman', [
        '$provide', 'shrub-requireProvider'
        ($provide, {require}) ->

          config = require 'config'
          debug = require('debug') 'shrub:pkgman'
          pkgman = require 'pkgman'

          debug 'Loading packages...'

Load the package list from configuration.

          pkgman.registerPackageList config.get 'packageList'

          debug 'Packages loaded.'

Simply pass along pkgman as the 'service'.

          pkgman.$get = -> pkgman

          return pkgman
      ]
