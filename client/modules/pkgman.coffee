
# # Package manager

_ = require 'underscore'

debug = require('debug') 'shrub:pkgman'

packageCache = null
_packages = []

class PkgmanRegistrar

	constructor: (@_path) ->
	
	recur: (paths) ->
		
		for path in paths
			
			subpath = "#{@_path}/#{path}"
			submodule = require subpath
			submodule.pkgmanRegister? new PkgmanRegistrar subpath
		
	registerHook: (submodule, hook, impl) ->
		
		if impl?
			
			path = "#{@_path}/#{submodule}"
		
		else
			
			path = @_path
			impl = hook
			hook = submodule
			
		(packageCache[hook] ?= []).push path: path, impl: impl

optionalModule = (name) ->

# ## rebuildPackageCache
exports.rebuildPackageCache = (type) ->
	packageCache = {}
	
	modules = {}
	for name in _packages
		
		try
			
			module_ = require name
		
		catch error
			
			# Suppress missing package errors.
			if error.toString() is "Error: Cannot find module '#{name}'"
				debug "Missing package #{name}."
				continue 
			
			throw error
	
		modules[name] = module_
		debug "Found package #{name}."
	
	# Collect hooks.
	for path, module_ of modules
		module_.pkgmanRegister? new PkgmanRegistrar path
	
	return

# ## registerPackageList
exports.registerPackageList = (packages, type) ->
	_packages.push.apply _packages, packages
	exports.rebuildPackageCache type
	
# ## invoke
# 
# Invoke a hook with arguments. Return the result as an object, keyed by
# package path.
exports.invoke = (hook, args...) ->
	
	results = {}
	return results unless packageCache?
	
	results[path] = impl args... for {path, impl} in packageCache[hook] ? []
	results

# ## invokeFlat
# 
# Invoke a hook with arguments. Return the result as an array.
exports.invokeFlat = (hook, args...) ->
	return [] unless packageCache?

	impl args... for {impl} in packageCache[hook] ? []
