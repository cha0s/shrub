
# # Schema
# 
# Provide the JugglingDB schema as an Angular service.

i8n = require 'inflection'
pkgman = require 'pkgman'
{Schema} = require 'promised-jugglingdb'

config = require 'config'

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$http'
		($http) ->
	
			schema = exports.define(
				require 'jugglingdb-rest'
				$http: $http
				apiRoot: config.get 'apiRoot'
			)
			
			schema.definePackageModels()
			
			schema
			
	]

# ## Schema::definePackageModels
# 
# Let packages define models.
Schema::definePackageModels = ->

	# Invoke hook `models`.
	# Allows packages to create models in the database schema.
	pkgman.invoke 'models', @

	# Invoke hook `modelsAlter`.
	# Allows packages to alter any models defined.
	pkgman.invoke 'modelsAlter', @models, @

# ## Schema::resourcePaths
# 
# Translate model names to REST resource/collection paths.
# `'CatalogEntry'` -> `['catalog-entry', 'catalog-entries']`
Schema::resourcePaths = (name) ->

	resource = i8n.dasherize(i8n.underscore name).toLowerCase()
	
	resource: resource
	collection: i8n.pluralize resource

# ## define
# 
# Define the JugglingDB schema.
exports.define = (adapter, options = {}) ->
	
	new Schema adapter, options
