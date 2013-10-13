
## The database schema

exports.define = (Schema, adapter, options = {}) ->
	
	schema = new Schema adapter, options
	
	schema.define 'User',
		
		name: type: String, length: 255, default: 'Anonymous'
	
	schema
