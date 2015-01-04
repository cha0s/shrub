
# # Titles

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `controller`
	registrar.registerHook 'controller', -> [
		'shrub-ui/window-title'
		class WindowTitleController
			
			constructor: (@_windowTitle) ->
		
			link: (scope, element, attrs) ->
				
				scope.$watch(
					-> @_windowTitle.get()
					-> scope.windowTitle = @_windowTitle.get()
				)
				
	]
	
	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
		
			directive = {}
			
			directive.bindToController = true
			
			directive.scope = {}
			
			directive
			
	]
	
	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		'shrub-ui/window-title'
		(windowTitle) ->
		
			# Set the site name into the window title.
			windowTitle.setSite config.get 'packageConfig:shrub-core:siteName'
			
	]
	
	# ## Implements hook `routeControllerStart`
	registrar.registerHook 'routeControllerStart', -> [
		'route', 'shrub-ui/window-title'
		(route, windowTitle) -> windowTitle.setPage route.title ? ''	
	]
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$interval'
		($interval) ->
			
			service = {}
			
			# Get and set the page title.
			_page = ''
			
			service.page = -> _page
			service.setPage = (page, setWindow = true) ->
				
				_page = page
				
				service.set [_page, _site].join _separator if setWindow
			
			# Get and set the token that separates the page and window title.
			_separator = ' · '
	
			service.separator = -> _separator
			service.setSeparator = (separator) -> _separator = separator
			
			# Get and set the site name.		
			_site = ''
	
			service.site = -> _site
			service.setSite = (site) -> _site = site
			
			# Get and set the window title.		
			_window = ''
	
			service.get = -> _windowWrapper _window
			service.set = (window) -> _window = window
			
			# Certain things will want to make the window/tab title flash for
			# attention. Those things will use this API to do so.
			_flashUpWrapper = (text) -> "¯¯¯#{text.toUpperCase()}¯¯¯"
			_flashDownWrapper = (text) -> "___#{text}___"
			_windowWrapper = angular.identity
			
			flashInProgress = null
			
			service.flash = ->
				return if flashInProgress?
				
				flashInProgress = $interval(
					->
					
						if _windowWrapper is _flashUpWrapper
							_windowWrapper = _flashDownWrapper
						else
							_windowWrapper = _flashUpWrapper
						
					600
				)
				
			# Restore the window/tab title to normal again.
			service.stopFlashing = ->
				
				$interval.cancel flashInProgress if flashInProgress?
				flashInProgress = null
				
				_windowWrapper = angular.identity
			
			# The wrappers below handle rendering the window title and flash
			# states. The wrappers are passed in a single argument, the title text.
			# The wrapper function returns another string, which is the text after
			# whatever wrapping you'd like to do.
			
			# Get and set the window title wrapper.		
			service.windowWrapper = -> _windowWrapper
			service.setWindowWrapper = (windowWrapper) -> _windowWrapper = windowWrapper
			
			# Get and set the flash down state wrapper.
			service.flashDownWrapper = -> _flashDownWrapper
			service.setFlashDownWrapper = (flashDownWrapper) -> _flashDownWrapper = flashDownWrapper
			
			# Get and set the flash up state wrapper.
			service.flashUpWrapper = -> _flashUpWrapper
			service.setFlashUpWrapper = (flashUpWrapper) -> _flashUpWrapper = flashUpWrapper
	
			service
			
	]
