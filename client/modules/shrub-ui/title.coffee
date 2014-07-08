
# # Titles

# ## Implements hook `directive`
exports.$directive = -> [
	'shrub-ui/title'
	({window}) ->
	
		link: (scope, elm, attr) ->
			
			# Keep the window title synchronized. 
			scope.$watch(
				-> window()
				-> scope.windowTitle = window()
			)
		
]

# ## Implements hook `routeControllerStart`
exports.$routeControllerStart = -> [
	'route', 'shrub-ui/title'
	(route, title) -> title.setPage route.title ? ''	
]

# ## Implements hook `service`
exports.$service = -> [
	'$interval'
	($interval) ->
		
		service = {}
		
		# Get and set the page title.
		_page = ''
		
		service.page = -> _page
		service.setPage = (page, setWindow = true) ->
			
			_page = page
			
			service.setWindow [_page, _site].join _separator if setWindow
		
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

		service.window = -> _windowWrapper _window
		service.setWindow = (window) -> _window = window
		
		# Certain things will want to make the window/tab title flash for
		# attention. Those things will use this API to do so.
		_flashUpWrapper = (text) -> "¯¯¯#{text.toUpperCase()}¯¯¯"
		_flashDownWrapper = (text) -> "___#{text}___"
		_windowWrapper = angular.identity
		
		flashInProgress = null
		
		service.flash = ->
			
			# Don't queue up a million timeouts.
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
