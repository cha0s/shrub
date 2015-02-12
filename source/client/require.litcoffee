
# Require system for Angular

*Implement require in the spirit of NodeJS.*

Resolve the module name.

    _resolveModuleName = (name, parentFilename) ->

Strip `/index` from the end, if necessary.

      checkModuleName = (name) ->
        return name if requires_[name]?
        return "#{name}/index" if requires_["#{name}/index"]?

      return checked if (checked = checkModuleName name)?

Resolve relative paths. We have to check methods on `path`. See below for more.

      path = _require 'path'
      return checked if (checked = checkModuleName(
        path.resolve(path.dirname(parentFilename), name).substr 1
      ))? if path.dirname? and path.resolve?

Oops, nothing resolved...

      throw new Error "Cannot find module '#{name}'"

Internal require function. Uses the parent filename to resolve relative paths.

    _require = (name, parentFilename) ->

Module inclusion is cached.

      unless requires_[name = _resolveModuleName name, parentFilename].module?

Extract the module function ahead of time, so we can set up module/exports and
assign it to the old value. Setting this up ahead of time avoids cycles.

        f = requires_[name]
        exports = {}
        module = exports: exports
        requires_[name] = module: module

Include `path`, you may observe that this is dangerous because we're within
the require system itself. This is correct and we have to check for `dirname`
to ensure the object has been required and populated.

        path = _require 'path'
        __dirname = (path.dirname? name) ? ''
        __filename = name

Execute the top-level module function, passing in all of our objects.

        f(
          module, exports, (name) -> _require name, __filename
          __dirname, __filename
        )

      requires_[name].module.exports

Provide require API to Angular.

    require = (name) -> _require name, ''
    angular.module('shrub.require', []).provider 'shrub-require', ->
      require: require
      $get: -> require
