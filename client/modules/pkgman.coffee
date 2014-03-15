
packageCache = null
_packages = []

exports.rebuildPackageCache = ->
	packageCache = {}
	
	for name in _packages
	
		try
			package_ = require "packages/#{name}"
		catch error
			
			continue if error.toString() is "Error: Cannot find module 'packages/#{name}'"
				
			throw error
			
		packageCache[name] = package_
		
	return

exports.registerPackages = (packages) ->
	
	_packages.push.apply _packages, packages
	
	exports.rebuildPackageCache()

exports.invoke = (hook, args...) ->
	exports.rebuildPackageCache() unless packageCache?
	
	results = {}
	
	invokeRecursive = (path, parent) ->
		
		for key, objectOrFunction of parent
			
			if key.charCodeAt(0) is '$'.charCodeAt(0)
	
				if key is "$#{hook}"
					
					results[path] = objectOrFunction args...
					
			else
				
				invokeRecursive "#{path}/#{key}", objectOrFunction
				
	invokeRecursive name, package_ for name, package_ of packageCache
	
	results
