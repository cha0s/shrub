# Implement require in the spirit of NodeJS.

require = (name) ->

	key = name
	
	# Check for index file in named directory.
	key = "#{key}/index" unless requires_[key]?
		
	throw new Error "Cannot find module '#{name}'" unless requires_[key]?
	
	unless requires_[key].module?
		exports = {}
		module = exports: exports
		
		f = requires_[key]
		requires_[key] = module: module
		
		f.call null, module, exports, require
		
	requires_[key].module.exports

angular.module('shrub.require', []).provider 'require', ->
	require: require
	$get: -> require
