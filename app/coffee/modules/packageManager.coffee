
# TODO actually discover packages.
exports.discoverPackages = ->
	
	['core', 'comm', 'user']

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
		
exports.loadAttribute = (name, fn) ->
		
	packageList = exports.discoverPackages()
	recursiveLoad packageName, name, fn for packageName in packageList
