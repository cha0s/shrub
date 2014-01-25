















unauthorized = ->
	error = new Error "Unauthorized access attempt"
	error.code = 401
	error
	
exports.wrapModel = (Model) ->
	
	access = {}
	schema = Model.schema
	{resource, collection} = schema.resourcePaths Model.modelName	
	
	# ExCEPTional hackage!
	Model.own = (filters, fn) ->
		all = schema.adapter.all
		schema.adapter.all = schema.adapter.own
		Model.all filters, fn
		schema.adapter.all = all
	
	access["get all #{collection}"] = (user, params, fn) ->
		unless fn?
			fn = params
			params = {}
		
		Model.all params, fn
		
	access["get own #{collection}"] = (user, params, fn) ->
		unless fn?
			fn = params
			params = {}
		
		# Exceptions, cool...
		switch resource
			when 'user'
				params.where.id = user.id
			
			else
				params.where.userId = user.id
				
		Model.own params, fn
		
	access["create a #{resource}"] = (user, attributes, fn) ->
		Model.create attributes, fn
		
	access["count #{collection}"] = (user, fn) ->
		Model.count fn
		
	access["delete all #{collection}"] = (user, fn) ->
		Model.destroyAll fn
		
	access["get a #{resource}"] = (user, id, fn) ->
		Model.find id, fn
		
	access["update a #{resource}"] = (user, id, attributes, fn) ->
		Model.find id, (error, model) ->
			return fn error if error?
			model.updateAttributes attributes, fn
			
	access["delete a #{resource}"] = (user, id, fn) ->
		schema.adapter.destroy name, id, fn
		
	access["check a #{resource}'s existence"] = (user, id, fn) ->
		Model.exists id, fn
		
	Model.access = ->
		args = (arg for arg in arguments)
		perm = args.shift()
		user = args[0]
		fn = args[args.length-1]
		
		return fn new Error "No such permission: #{perm}" unless access[perm]?
		return fn unauthorized() unless user.hasPermission perm
		
		access[perm].apply null, args
	
	# Chain!
	Model
