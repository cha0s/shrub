# # Configuration system.
#
# *Handle getting, setting, and checking configuration state.*
module.exports = new class Config

  # This class allows us to wrap and subsequently get, set, and check the
  # existence of values in a configuration tree. The configuration tree may be
  # traversed with colons, e.g. `parent:child:grandchild`. Supposing we have a
  # configuration structure:
  #
  # ```coffeescript
  # configuration =
  #   visible: true
  #   child:
  #     id: 200
  #     tag: null
  # ```
  #
  # We may wrap and interact with it as follows:
  #
  # ```coffeescript
  # wrapped = new Config configuration
  # wrapped.get 'visible'
  # ```
  #
  # Returns: `true`
  #
  # ```coffeescript
  # wrapped.set 'child:name', 'Billy'
  # wrapped.get 'child'
  # ```
  #
  # Returns: `{ id: 200, name: 'Billy' }`
  #
  # ```coffeescript
  # wrapped.has 'child:id'
  # ```
  #
  # Returns: `true`
  #
  # ```coffeescript
  # wrapped.has 'child:thing'
  # ```
  #
  # Returns: `false`
  #
  # **NOTE:** `has` works with null values:
  #
  # ```coffeescript
  # wrapped.has 'child:tag'
  # ```
  #
  # Returns: `true`
  #
  # ## Provide the class externally.
  Config: Config

  # ## *constructor*
  #
  # * (object) `config` - The configuration tree.
  #
  # *Create a configuration wrapper.*
  constructor: (config = {}) -> @from config

  # ## Config#from
  #
  # * (object) `config` - The configuration object.
  #
  # *Set configuration from an object.*
  from: (@config) ->

  # ## Config#get
  #
  # * (string) `path` - The path to look up, e.g. parent:child:grandchild
  #
  # *Get a value by path.*
  get: (path) ->

    current = @config
    for part in path.split ':'
      current = current?[part]
    current

  # ## Config#has
  #
  # * (string) `path` - The path to look up, e.g. `'parent:child:grandchild'`
  #
  # *Check whether a path exists.*
  has: (path) ->

    current = @config
    for part in path.split ':'
      return false unless part of current
      current = current[part]

    return true

  # ## Config#set
  #
  # * (string) `path` - The path to look up, e.g. parent:child:grandchild
  #
  # * (any) `value` - The value to store at the path location.
  #
  # *Set a value by path.*
  set: (path, value) ->

    [parts..., last] = path.split ':'
    current = @config
    for part in parts
      current = (current[part] ?= {})

    current[last] = value

  # ## Config#toJSON
  #
  # *Return config object for serialization.*
  toJSON: -> @config
