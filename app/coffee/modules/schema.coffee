
exports.define = (Schema, schema) ->
	
	models =
	
		Post:
			
			spec:
		
				title:     type: String, length: 255
				content:   type: Schema.Text
				date:      type: Date,    default: -> new Date
				timestamp: type: Number,  default: Date.now
				published: type: Boolean, default: false, index: true
			
	schema.define name, spec for name, {spec} of models
	
	models
