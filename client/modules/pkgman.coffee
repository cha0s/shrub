
# # Package manager

debug = require('debug') 'shrub:pkgman'
debugSilly = require('debug') 'shrub-silly:pkgman'

packageIndex = null
pathIndex = null

_packages = []

class PkgmanRegistrar

	constructor: (@_path) ->

	path: -> @_path

	recur: (paths) ->

		for path in paths

			subpath = "#{@_path}/#{path}"

			debugSilly "Requiring #{subpath}"
			submodule = require subpath
			debugSilly "Required #{subpath}"

			debugSilly "Registering hooks for #{subpath}"
			submodule.pkgmanRegister? new PkgmanRegistrar subpath
			debugSilly "Registered hooks for #{subpath}"

		return

	registerHook: (submodule, hook, impl) ->

		if impl?

			path = "#{@_path}/#{submodule}"

		else

			path = @_path
			impl = hook
			hook = submodule

		debugSilly "Registering hook #{hook}"

		(packageIndex[hook] ?= []).push path
		(pathIndex[path] ?= {})[hook] = impl

		debugSilly "Registered hook #{hook}"

optionalModule = (name) ->

# ## rebuildPackageCache
exports.rebuildPackageCache = (type) ->
	modules = {}
	packageIndex = {}
	pathIndex = {}

	for name in _packages

		try

			debugSilly "Requiring package #{name}"

			module_ = require name

		catch error

			# Suppress missing package errors.
			if error.toString() is "Error: Cannot find module '#{name}'"
				debug "Missing package #{name}."
				continue

			throw error

		debugSilly "Required package #{name}"

		modules[name] = module_

	# Collect hooks.
	for path, module_ of modules

		debugSilly "Registering hooks for #{path}"
		module_.pkgmanRegister? new PkgmanRegistrar path
		debugSilly "Registered hooks for #{path}"

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

exports.packageExists = (name) -> -1 isnt _packages.indexOf name

exports.packagesImplementing = (hook) -> packageIndex?[hook] ? []

# Normalize paths, e.g.
# 'core/foo/bar' -> 'coreFooBar'
exports.normalizePath = (path) ->

	i8n = require 'inflection'

	parts = for part, i in path.split '/'
		i8n.camelize(
			part.replace /[^\w]/g, '_'
			0 is i
		)

	i8n.camelize (i8n.underscore parts.join ''), true
