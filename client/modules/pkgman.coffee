
# # Package manager
#
# *Registers packages and handles hook registration and invocation as well as
# introspection.*
debug = require('debug') 'shrub:pkgman'
debugSilly = require('debug') 'shrub-silly:pkgman'

# Index by hook and path for faster invocation and introspection.
hookIndex = {}
pathIndex = {}

# A list of registered packages.
_packages = []

# Registrar object passed to packages to allow them to register hooks and/or
# recur into their own subpackages to allow them to.
class PkgmanRegistrar

  # ## *constructor*
  #
  # *Instantiate the registrar with the current (sub)package path.*
  constructor: (@_path) ->

  # ## PkgmanRegistrar#path
  #
  # *Get the current (sub) package path.*
  path: -> @_path

  # ## PkgmanRegistrar#recur
  #
  # * (string array) `paths` - The list of submodule paths to register.
  #
  # *Recur into subpackages to register them and allow them to register hooks
  # and/or recur further.*
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

  # ## PkgmanRegistrar#registerHook
  #
  # * (optional string) `submodule` - Register this hook under a submodule.
  # This is
  #
  # a convenience for when you might need to register more than one
  # implementation of a hook, bur prefer to keep both implementations in the
  # same physical file.
  #
  # * (string) `hook` - The name of the hook to register.
  #
  # * (function) `impl` - The hook implementation function. This is invoked
  # when
  #
  # the hook is invoked. The signature of the implementation function may
  # vary, consult the documentation for the specific hook to learn more.
  #
  # ###### TODO: Link to an instance of using the `submodule` arg in core if
  # one exists.
  registerHook: (submodule, hook, impl) ->

    # If `submodule` was passed in, modify the path this hook is registered
    # against.
    if impl?

      path = "#{@_path}/#{submodule}"

    # Otherwise, fix up the args.
    else

      path = @_path
      impl = hook
      hook = submodule

    # Populate the indexes with the registered hook.
    debugSilly "Registering hook #{hook}"

    (hookIndex[hook] ?= []).push path
    (pathIndex[path] ?= {})[hook] = impl

    debugSilly "Registered hook #{hook}"

# ## pkgman.rebuildPackageCache
#
# *Rebuild the package cache.* **Do not invoke this unless you are absolutely
# sure you know what you're doing.**
exports.rebuildPackageCache = ->
  modules = {}
  hookIndex = {}
  pathIndex = {}

  for name in _packages

    # Try to require the package module.
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

  # Register hooks.
  for path, module_ of modules

    debugSilly "Registering hooks for #{path}"
    module_.pkgmanRegister? new PkgmanRegistrar path
    debugSilly "Registered hooks for #{path}"

  return

# ## pkgman.registerPackageList
#
# * (string array) `packages` - The list of packages to register.
#
# *Register a list of packages.*
exports.registerPackageList = (packages) ->
  _packages.push.apply _packages, packages
  exports.rebuildPackageCache()

# ## pkgman.invoke
#
# * (string) `hook` - The name of the hook to invoke.
#
# * (args...) `args` - Arguments to pass along to implementations of the hook.
#
# *Invoke a hook with arguments. Return the result as an object, keyed by
# package path.*
exports.invoke = (hook, args...) ->

  results = {}

  for path in exports.packagesImplementing hook
    results[path] = exports.invokePackage path, hook, args...

  return results

# ## pkgman.invokeFlat
#
# * (string) `hook` - The name of the hook to invoke.
#
# * (args...) `args` - Arguments to pass along to implementations of the hook.
#
# *Invoke a hook with arguments. Return the result as an array.*
exports.invokeFlat = (hook, args...) ->

  for path in exports.packagesImplementing hook
    exports.invokePackage path, hook, args...

# ## pkgman.invokePackage
#
# * (string) `path` - The path of the package whose implementation we're
#
# invoking.
#
# * (string) `hook` - The name of the hook to invoke.
#
# * (args...) `args` - Arguments to pass along to the hook implementation.
#
# *Invoke a package's implementation of a hook with arguments. Return the
# result.*
exports.invokePackage = (path, hook, args...) ->
  pathIndex?[path]?[hook]? args...

# ## pkgman.packageExists
#
# * (string) `name` - The name of the package to check.
#
# *Check whether a package exists.*
exports.packageExists = (name) -> -1 isnt _packages.indexOf name

# ## pkgman.packagesImplementing
#
# * (string) `hook` - The hook to check.
#
# *Return a list of packages implementing the hook.*
exports.packagesImplementing = (hook) -> hookIndex?[hook] ? []

# ## pkgman.normalizePath
#
# * (string) `path` - The path to normalize.
#
# * (Boolean) `capitalize` - Whether to capitalize the first letter.
#
# *Converts a package path (e.g. `shrub-user/login`) to a normalized path
# (e.g. `shrubUserLogin`).*
exports.normalizePath = (path, capitalize = false) ->

  i8n = require 'inflection'

  parts = for part, i in path.split '/'
    i8n.camelize i8n.underscore(
      part.replace /[^\w]/g, '_'
      0 is i
    )

  i8n.camelize (i8n.underscore parts.join ''), not capitalize