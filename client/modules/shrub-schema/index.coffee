
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
	
			schema = define(
				require 'jugglingdb-rest'
				$http: $http
				apiRoot: config.get 'apiRoot'
			)
			
			schema.definePackageModels()
			
			schema
			
	]

# Translate model names to REST resource/collection paths.
# `'CatalogEntry'` -> `['catalog-entry', 'catalog-entries']`
Schema::resourcePaths = (name) ->

	resource = i8n.dasherize(i8n.underscore name).toLowerCase()
	
	resource: resource
	collection: i8n.pluralize resource

# ## define
# 
# Define the JugglingDB schema.
define = exports.define = (adapter, options = {}) ->
	
	schema = new Schema adapter, options
	
	# ## schema.definePackageModels
	# 
	# Let packages define JugglingDB models.
	schema.definePackageModels = ->
		
		# Invoke hook `models`.
		# Allows packages to create models in the database schema.
		pkgman.invoke 'models', schema
	
		# Invoke hook `modelsAlter`.
		# Allows packages to alter any models defined.
		pkgman.invoke 'modelsAlter', schema.models, schema
		
	schema
