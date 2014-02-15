# Implement require in the spirit of NodeJS.

require = (name) ->

	unless requires_[name]?
		throw new Error "Module #{name} not found!"
	
	unless requires_[name].module?
		exports = {}
		module = exports: exports
		
		f = requires_[name]
		requires_[name] = module: module
		
		f.call null, module, exports, require
		
	requires_[name].module.exports

angular.module('shrub.require', []).provider 'require', ->
	require: require
	$get: -> require

# Package automation.
i8n = require 'inflection'
pkgman = require 'pkgman'

types = ['directive', 'service']
for type in types
	
	names = []
	
	pkgman.invoke type, (path, spec) ->
		
		names.push name = "shrub.packages.#{type}.#{path}"
		$module = angular.module name, []
		
		# Use camelized names for directives:
		# 'core/foo/bar' -> 'coreFooBar'
		if type is 'directive'
			path = path.replace '/', '_'
			path = i8n.camelize path.toLowerCase(), true
			
		$module[type] path, spec
		
	angular.module "shrub.packages.#{type}", names
		
angular.module(
	"shrub.packages"
	"shrub.packages.#{type}" for type in types
)
