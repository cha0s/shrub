
## The database schema

i8n = require 'inflection'
pkgman = require 'pkgman'
Schema = (require 'jugglingdb-client').Schema

# Translate model names to REST resource/collection paths.
# 'CatalogEntry' -> ['catalog-entry', 'catalog-entries']
Schema::resourcePaths = (name) ->

	resource = i8n.underscore name
	resource = i8n.dasherize resource.toLowerCase()
	
	resource: resource
	collection: i8n.pluralize resource

exports.define = (adapter, options = {}) ->
	
	schema = new Schema adapter, options
	
	pkgman.invoke 'models', schema
	pkgman.invoke 'modelsAlter', schema.models, schema
	
	schema
