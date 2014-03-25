
url = require 'url'

_ = require 'underscore'
nconf = require 'nconf'
Promise = require 'bluebird'

Config = (require 'config').Config
pkgman = require 'pkgman'

exports.$config = (req) ->
	
	baseUrl: "//#{req.headers.host}"
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
			
			Promise.all(
				pkgman.invokeFlat 'config', req
				
			).then((subconfigs) ->

				config = {}
				_.extend config, subconfig for subconfig in subconfigs				
			
				prettyPrintConfig = ->
					[first, rest...] = (JSON.stringify config, null, '  ').split '\n'
					([first].concat rest.map (line) -> '  ' + line).join '\n'
					
				res.setHeader 'Content-Type', 'text/javascript'
				
				res.send """
angular.module('shrub.config', []).provider('config', function() {

  var __slice = [].slice;
  
  return new ((#{Config.toString()})())(#{prettyPrintConfig()});

});
"""
				
			).catch next
			
	]

exports.$replContext = (context) -> context.config = nconf
