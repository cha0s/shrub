
packageCache = null
_packages = []

exports.rebuildPackageCache = ->
	moduleCache = {}
	packageCache = {}
	
	for name in _packages
	
		try
			package_ = require "packages/#{name}"
		catch error
			
			continue if error.toString() is "Error: Cannot find module 'packages/#{name}'"
				
			throw error
			
		moduleCache[name] = package_
		
	cacheRecursive = (path, parent) ->
		
		for key, objectOrFunction of parent
			
			if key.charCodeAt(0) is '$'.charCodeAt(0)
				
				(packageCache[key.slice 1] ?= []).push
					path: path
					fn: objectOrFunction
	
			else
				
				cacheRecursive "#{path}/#{key}", objectOrFunction
				
	cacheRecursive path, module for path, module of moduleCache
		
	return

exports.registerPackages = (packages) ->
	
	_packages.push.apply _packages, packages
	
	exports.rebuildPackageCache()

exports.invoke = (hook, args...) ->
	exports.rebuildPackageCache() unless packageCache?
	
	results = {}
	results[path] = fn args... for {path, fn} in packageCache[hook] ? []
	results
