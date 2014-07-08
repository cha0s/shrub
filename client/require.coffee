
# # Require
# 
# Implement require in the spirit of NodeJS.

# Resolve the module name. Handles relative paths, as well as stripping
# `/index` from the end, if necessary.
_resolveModuleName = (name, parentFilename) ->
	
	checkModuleName = (name) ->
		return name if requires_[name]?
		return "#{name}/index" if requires_["#{name}/index"]?
		
	return checked if (checked = checkModuleName name)?
	
	# Resolve relative paths.
	path = _require 'path'
	return checked if (checked = checkModuleName(
		path.resolve(
			path.dirname parentFilename
			name
		).substr 1
	))?
	
	throw new Error "Cannot find module '#{name}'"

_require = (name, parentFilename) ->
	
	name = _resolveModuleName name, parentFilename
	
	unless requires_[name].module?

		# Extract the module function.
		f = requires_[name]
		
		# Set up module and exports. Assign it to the requires_ object, to
		# allow require cycles.
		exports = {}
		module = exports: exports
		requires_[name] = module: module
		
		# Need to check for dirname, since when 'path' is required the first
		# time, it won't be available.
		path = _require 'path'
		__dirname = (path.dirname? name) ? ''
		__filename = name
		
		# Execute the module body.
		f(
			module, exports
			(name) -> _require name, __filename
			__dirname, __filename
		)
		
	requires_[name].module.exports

require = (name) -> _require name, ''

# Implement an Angular module to provide require functionality.
angular.module('shrub.require', []).provider 'shrub-require', ->
	require: require
	$get: -> require
