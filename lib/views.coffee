
path = require 'path'

module.exports = new class

	initialize: (app) ->
	
# Handlebars, by default.
	
		app.set 'views', path.join __dirname, '..', 'app'
		app.set 'view engine', 'html'
		app.engine 'html', require('hbs').__express
