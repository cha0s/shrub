
# TODO actually discover packages.
exports.discoverPackages = ->
	
	['user']

recursiveLoad = (packageName, key, fn) ->

	# TODO only until I improve require()
	try
		packageComponents = require "packages/#{packageName}"
	catch error
		packageComponents = require "packages/#{packageName}/index"
	
	for packageKey, packageSpec of packageComponents
		
		if packageKey.charCodeAt(0) is '$'.charCodeAt(0)
			
			if packageKey is "$#{key}"
				fn packageName, packageKey, packageSpec
				
		else
			
			recursiveLoad "#{packageName}/#{packageKey}", key, fn
		
exports.loadEndpoints = (fn) ->
	
	packageList = exports.discoverPackages()
	
	# Load package endpoints.
	for packageName in packageList
		recursiveLoad packageName, 'endpoint', fn

exports.loadRoutes = (fn) ->
	
	packageList = exports.discoverPackages()
	
	# Load package endpoints.
	for packageName in packageList
		recursiveLoad packageName, 'route', fn
