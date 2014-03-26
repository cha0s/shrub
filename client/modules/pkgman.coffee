
# # Package manager

packageCache = null
_packages = []

# ## rebuildPackageCache
exports.rebuildPackageCache = ->
	packageCache = {}
	
	modules = {}
	for name in _packages
	
		try
			modules[name] = require "packages/#{name}"
		catch error
			
			# Suppress missing package errors.
			# `TODO`: Should we let this throw?
			continue if error.toString() is "Error: Cannot find module 'packages/#{name}'"
			throw error
	
	# Recur down the package tree and collect hooks.		
	cacheRecursive = (path, parent) ->
		
		for key, objectOrFunction of parent
			
			# It's a hook, cache it.
			if key.charCodeAt(0) is '$'.charCodeAt(0)
				(packageCache[key.slice 1] ?= []).push
					path: path
					fn: objectOrFunction
	
			else
				
				# Recur.
				cacheRecursive "#{path}/#{key}", objectOrFunction
				
	cacheRecursive path, module for path, module of modules
		
	return

# ## registerPackageList
exports.registerPackageList = (packages) ->
	_packages.push.apply _packages, packages
	exports.rebuildPackageCache()

# ## invoke
# 
# Invoke a hook with arguments. Return the result as an object, keyed by
# package path.
exports.invoke = (hook, args...) ->
	exports.rebuildPackageCache() unless packageCache?
	
	results = {}
	results[path] = fn args... for {path, fn} in packageCache[hook] ? []
	results

# ## invokeFlat
# 
# Invoke a hook with arguments. Return the result as an array.
exports.invokeFlat = (hook, args...) ->
	exports.rebuildPackageCache() unless packageCache?
	
	fn args... for {fn} in packageCache[hook] ? []
	