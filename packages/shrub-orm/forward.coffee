
User:
	
	fields:
		
		name:
			
			type: String
			default: 'Anonymous'
			length: 24
			
	methods:
	
		isActive: ->
	
	statics:
		
		getAllActive: ->

class Schema
	
	constructor: ->
	
	collectModels: ->
	
	defineModel: (model) ->

modelsList = pkgman.invokeFlat 'models'
pkgman.invoke 'modelsAlter', modelsList

for models in modelsList
	for name, model of models
		