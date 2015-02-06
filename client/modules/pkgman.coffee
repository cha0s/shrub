
# # Package manager

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

			debug "Requiring #{subpath}"
			submodule = require subpath
			debug "Required #{subpath}"

			debug "Registering hooks for #{subpath}"
			submodule.pkgmanRegister? new PkgmanRegistrar subpath
			debug "Registered hooks for #{subpath}"

		return

	registerHook: (submodule, hook, impl) ->

		if impl?

			path = "#{@_path}/#{submodule}"

		else

			path = @_path
			impl = hook
			hook = submodule

		debug "Registering hook #{hook}"

		(packageIndex[hook] ?= []).push path
		(pathIndex[path] ?= {})[hook] = impl

		debug "Registered hook #{hook}"

optionalModule = (name) ->

# ## rebuildPackageCache
exports.rebuildPackageCache = (type) ->
	modules = {}
	packageIndex = {}
	pathIndex = {}

	for name in _packages

		try

			debug "Requiring #{name}"

			module_ = require name

		catch error

			# Suppress missing package errors.
			if error.toString() is "Error: Cannot find module '#{name}'"
				debug "Missing package #{name}."
				continue

			throw error

		debug "Required #{name}"

		modules[name] = module_

	# Collect hooks.
	for path, module_ of modules

		debug "Registering hooks for #{path}"
		module_.pkgmanRegister? new PkgmanRegistrar path
		debug "Registered hooks for #{path}"

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
