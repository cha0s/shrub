
_ = require 'underscore'
nconf = require 'nconf'
pkgman = require 'pkgman'

module.exports.middleware = (http) -> [
	
	(req, res, next) ->
		return next() unless req.url is '/js/config.js'
		
		config = {}
		
		config.useMocks = process.env['E2E']?
		config.debugging = 'production' isnt nconf.get 'NODE_ENV'
			
		pkgman.invoke 'config', (path, spec) ->
			
			_.extend config, spec
		
		prettyPrintConfig = ->
			[first, rest...] = (JSON.stringify config, null, '\t').split '\n'
			([first].concat rest.map (line) -> '\t' + line).join '\n'
			
		res.setHeader 'Content-Type', 'text/javascript'
		
		res.send """
angular.module('shrub.config', []).provider('config', function() {

	var _config = #{prettyPrintConfig()};
	
	var get = function(key) { return _config[key]; };
	var has = function(key) { return _config[key] != null; };
	var set = function(key, value) { return _config[key] = value; };
	
	return {
		
		get: get,
		has: has,
		set: set,
		
		$get: function() { return {get: get, has: has, set: set}; }
	}
	
});
"""
		
	(req, res, next) ->
		
		config =
			debugging: 'production' isnt req.app.get 'env'
		
		res.locals.configJson = JSON.stringify config
		
		res.locals.assets =
		
			js: if 'production' is nconf.get 'NODE_ENV'
				
				[
					'/lib/underscore/underscore-min.js'
	
					'//code.jquery.com/jquery-1.9.1.min.js'
					
					'/lib/bootstrap/js/bootstrap.min.js'
					
					'/lib/socket.io/socket.io.min.js'
					
					'/js/before-angular.js'
				
					'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular.min.js'
					'//ajax.googleapis.com/ajax/libs/angularjs/1.0.4/angular-sanitize.min.js'
					'/lib/angular-strap/angular-strap.min.js'
					'/js/angular.min.js'
					
					'/js/modules.min.js'
					'/js/config.js'
				]
	
			else
				
				[
					'/lib/underscore/underscore.js'
					
					'/lib/jquery/jquery-1.9.js'
	
					'/lib/bootstrap/js/bootstrap.js'
			
					'/lib/socket.io/socket.io.js'
					
					'/js/before-angular.js'
					
					'/lib/angular/angular.js'
					'/lib/angular/angular-route.js'
					'/lib/angular/angular-sanitize.js'
					'/lib/angular-strap/angular-strap.js'
					'/js/app.js'
					
					'/js/modules.js'
					'/js/config.js'
					
#					if process.env['E2E']
#						'/js/mocks.js'
#					else
#						'/js/empty-mocks.js'
					
				]
				
		
		next()

]