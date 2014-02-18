
_ = require 'underscore'
nconf = require 'nconf'
pkgman = require 'pkgman'

exports.$config = (req) ->
	
	testMode: if (req.nconf.get 'E2E')? then 'e2e' else false
	debugging: 'production' isnt req.nconf.get 'NODE_ENV'
	packageList: req.nconf.get 'packageList'

exports.$httpMiddleware = (http) ->
	
	label: 'Serve package configuration'
	middleware: [

		(req, res, next) ->
			
			req.nconf = nconf
			
			next()
		
		(req, res, next) ->
			return next() unless req.url is '/js/config.js'
			
			config = {}
			pkgman.invoke 'config', (path, fn) -> _.extend config, fn req
			
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
	};
	
});
"""
			
	]
