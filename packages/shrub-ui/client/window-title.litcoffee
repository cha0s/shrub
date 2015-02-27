# UI - Window title

*Manage the window and page titles.*

    config = require 'config'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularController`.

      registrar.registerHook 'shrubAngularController', -> [
        'shrub-ui/window-title'
        class WindowTitleController

          constructor: (@windowTitle) ->

          link: (scope, element) ->
            self = this

            scope.$watch(
              -> self.windowTitle.get()
              -> element.text self.windowTitle.get()
            )

      ]

#### Implements hook `shrubAngularDirective`.

      registrar.registerHook 'shrubAngularDirective', -> [

        ->

          directive = {}

          directive.bindToController = true

          directive.scope = {}

          directive

      ]

#### Implements hook `shrubAngularAppRun`.

      registrar.registerHook 'shrubAngularAppRun', -> [
        '$rootScope', 'shrub-ui/window-title'
        ($rootScope, windowTitle) ->

Set the site name into the window title.

          windowTitle.setSite config.get 'packageConfig:shrub-core:siteName'

          $rootScope.$on '$routeChangeSuccess', (event, route) ->

            windowTitle.setPage route.$$route?.title ? ''

      ]

#### Implements hook `shrubAngularService`.

      registrar.registerHook 'shrubAngularService', -> [
        '$interval'
        ($interval) ->

          service = {}

          _page = ''

## windowTitle.page

*Get the page title.*

          service.page = -> _page

## windowTitle.setPage

* (String) `page` - The page title.
* (Boolean) `setWindow` - Update the window title.

*Set the page title.*

          service.setPage = (page, setWindow = true) ->

            _page = page
            service.set [_page, _site].join _separator if setWindow

          _separator = ' · '

## windowTitle.separator

*Get the token that separates the window and page titles.*

          service.separator = -> _separator

## windowTitle.setSeparator

* (String) `separator` - The separator.

*Set the token that separates the window and page titles.*

          service.setSeparator = (separator) -> _separator = separator

          _site = ''

## windowTitle.site

*Get the site name.*

          service.site = -> _site

## windowTitle.setSite

* (String) `site` - The site name.

*Set the site name.*

          service.setSite = (site) -> _site = site

          _window = ''

## windowTitle.get

*Get the window title.*

          service.get = -> _windowTitleWrapper _window

## windowTitle.set

* (String) `window` - The window title.

*Set the window title.*

          service.set = (window) -> _window = window

If you want to make the window/tab title flash for attention, use this API.

          _flashUpWrapper = (text) -> "¯¯¯#{text.toUpperCase()}¯¯¯"
          _flashDownWrapper = (text) -> "___#{text}___"
          _windowTitleWrapper = angular.identity

          flashInProgress = null

## windowTitle.startFlashing

*Start flashing the window title.*

          service.startFlashing = ->
            return if flashInProgress?

            flashInProgress = $interval(
              ->

                if _windowWrapper is _flashUpWrapper
                  _windowWrapper = _flashDownWrapper
                else
                  _windowWrapper = _flashUpWrapper

              600
            )

## windowTitle.stopFlashing

*Stop flashing the window title.*

          service.stopFlashing = ->

            $interval.cancel flashInProgress if flashInProgress?
            flashInProgress = null

            _windowWrapper = angular.identity

The wrappers below handle rendering the window title and flash states. The
wrappers are passed in a single argument, the title text. The wrapper function
returns another string, which is the text after whatever wrapping you'd like to
do.

## windowTitle.flashDownWrapper

*Get the transformation function for the 'down' flash.*

          service.flashDownWrapper = -> _flashDownWrapper

## windowTitle.setFlashDownWrapper

* (Function) `flashDownWrapper` - Transformation function. Takes the window
  title as argument and returns a transformed window title.

*Set the transformation function for the 'down' flash.*

          service.setFlashDownWrapper = (flashDownWrapper) ->
            _flashDownWrapper = flashDownWrapper

## windowTitle.flashUpWrapper

*Get the transformation function for the 'up' flash.*

          service.flashUpWrapper = -> _flashUpWrapper

## windowTitle.setFlashUpWrapper

* (Function) `flashUpWrapper` - Transformation function. Takes the window
  title as argument and returns a transformed window title.

*Set the transformation function for the 'up' flash.*

          service.setFlashUpWrapper = (flashUpWrapper) ->
            _flashUpWrapper = flashUpWrapper

          service

      ]
