exports.$service = [
	'$window'
	($window) ->

# We'll get a package of configuration from the server, in window.ReddiChat
# In testing, we won't receive that, so we'll also provide some defaults.
		_config = if $window.ShrubConfig?
			angular.copy $window.ShrubConfig
		else
			debugging: true

# Get a configuration value, check if a configuration key exists, and set a
# configuration key to a value, respectively.
		
		@get = (key) -> _config[key]
		@has = (key) -> _config[key]?
		@set = (key, value) -> _config[key] = value
		
		return

]
