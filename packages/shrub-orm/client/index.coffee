
# # [Object-relational mapping](http://en.wikipedia.org/wiki/Object-relational_mapping) using Waterline.
#
# browserify -r waterline-browser -x util -x assert -x events -x bluebird -x async -x lodash -x buffer -x anchor -x validator -x waterline-criteria -x waterline-schema > waterline-browser.js
#
# Provide the ORM as an Angular service.

Promise = require 'bluebird'

pkgman = require 'pkgman'

collections = {}

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `collectionsAlter`
#	registrar.registerHook 'collectionsAlter', (collections_) ->
#
#		collection.connection = 'socket' for collection in collections_

	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$http'
		($http) ->

			service = {}

			exports.initialize()

			service.collection = (identity) -> collections[identity]

			service.collections = -> collections

			service

	]

exports.initialize = ->

	# Invoke hook `collections`.
	# Allows packages to create Waterline collections.
	collections_ = {}
	for collectionList in pkgman.invokeFlat 'collections'
		for identity, collection of collectionList

			# Collection defaults.
			collection.identity ?= identity
			collections_[collection.identity] = collection

			# Instantiate a model with defaults supplied.
			collection.instantiate = (values = {}) ->
				model = JSON.parse JSON.stringify values

				for key, value of @attributes
					continue unless value.defaultsTo?

					model[key] ?= if 'function' is typeof value.defaultsTo
						value.defaultsTo.call model
					else
						JSON.parse JSON.stringify value.defaultsTo

				model

	# Invoke hook `collectionsAlter`.
	# Allows packages to alter any Waterline collections defined.
	pkgman.invoke 'collectionsAlter', collections_

	collections = collections_
