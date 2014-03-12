# Implement require in the spirit of NodeJS.

_resolveModuleName = (name, parentFilename) ->

	return name if requires_[name]
	
	return "#{name}/index" if requires_["#{name}/index"]?
	
	# Resolve relative paths.
	path = _require 'path'
	parentDirname = path.dirname parentFilename
	resolvedPath = (path.resolve parentDirname, name).substr 1

	return resolvedPath if requires_[resolvedPath]
	return "#{resolvedPath}/index" if requires_["#{resolvedPath}/index"]?
	
	throw new Error "Cannot find module '#{name}'"

_require = (name, parentFilename) ->
	
	name = _resolveModuleName name, parentFilename
	
	unless requires_[name].module?
		exports = {}
		module = exports: exports
		
		f = requires_[name]
		requires_[name] = module: module
		
		path = _require 'path'
		
		# Need to check for dirname, since when 'path' is required the first
		# time, it won't be available.
		__dirname = (path.dirname? name) ? ''
		__filename = name
		
		f(
			module, exports
			(name) -> _require name, __filename
			__dirname, __filename
		)
		
	requires_[name].module.exports

require = (name) -> _require name, ''

angular.module('shrub.require', []).provider 'require', ->
	require: require
	$get: -> require
