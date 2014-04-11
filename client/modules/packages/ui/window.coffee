
# # Window

# ## Implements hook `service`
exports.$service = -> [
	'$rootScope', '$window'
	($rootScope, $window) ->
		
		service = {}
		
		# Whether or not the window is active. This state maps 1:1 with the
		# 'focus' and 'blur' events on the window.
		_isActive = true
		
		angular.element($window).bind 'focus', ->
			$rootScope.$apply -> _isActive = true
			return
			
		angular.element($window).bind 'blur', ->
			$rootScope.$apply -> _isActive = false
			return
		
		service.isActive = -> _isActive
		
		# Set whether we will notify the user when they are trying to close
		# the tab. A truth value will notify the user, and a falsy value will
		# turn off notification if called with no argument, it will enable
		# notification.
		_notifyOnClose = null
		
		$window.onbeforeunload = -> _notifyOnClose
		
		service.notifyOnClose = (notifyOnClose = true) ->
			
			_notifyOnClose = if notifyOnClose then true else null
		
		service
			
]
