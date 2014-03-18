
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
			
			promises = for path, promise of pkgman.invoke 'config', req
				promise
			
			config = {}
			Promise.all(promises).then((subconfigs) ->
				_.extend config, subconfig for subconfig in subconfigs
			).then(->
				
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
				
				(error) -> next error
			)
			
	]

exports.$replContext = (context) -> context.config = nconf
