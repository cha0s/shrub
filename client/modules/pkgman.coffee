
# # Package manager

_ = require 'lodash'

debug = require('debug') 'shrub:pkgman'

packageIndex = null
pathIndex = null

_packages = []

class PkgmanRegistrar

	constructor: (@_path) ->
	
	path: -> @_path
	
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
			
		(packageIndex[hook] ?= []).push path
		(pathIndex[path] ?= {})[hook] = impl

optionalModule = (name) ->

# ## rebuildPackageCache
exports.rebuildPackageCache = (type) ->
	packageIndex = {}
	pathIndex = {}
	
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

	for path in exports.packagesImplementing hook
		results[path] = exports.invokePackage path, hook, args...
	
	return results

# ## invokeFlat
# 
# Invoke a hook with arguments. Return the result as an array.
exports.invokeFlat = (hook, args...) ->
	
	for path in exports.packagesImplementing hook
		exports.invokePackage path, hook, args...

exports.invokePackage = (path, hook, args...) ->
	pathIndex?[path]?[hook]? args...

exports.packagesImplementing = (hook) -> packageIndex[hook] ? []
