
invocationCache = {}
packageCache = null

exports.clearInvocationCache = (hook) ->
	
	if hook?
		invocationCache[hook] = null
	else
		invocationCache = {}
		
	return

exports.rebuildPackageCache = ->
	packageCache = {}
	
	for name in exports.discoverPackages()
	
		# TODO only until I improve require()
		package_ = try
			require "packages/#{name}"
		catch error
			require "packages/#{name}/index"
			
		packageCache[name] = package_
		
	return

# TODO actually discover packages.
exports.discoverPackages = ->
	
	['core', 'comm', 'user']

exports.invoke = (hook, fn) ->
	exports.rebuildPackageCache() unless packageCache?
	
	unless invocationCache[hook]?
		invocationCache[hook] = {}
		
		invokeRecursive = (path, parent) ->
			
			for key, spec of parent
				
				if key.charCodeAt(0) is '$'.charCodeAt(0)
		
					if key is "$#{hook}"
						
						invocationCache[hook][path] = spec
						
				else
					
					invokeRecursive "#{path}/#{key}", spec
					
		invokeRecursive name, package_ for name, package_ of packageCache
	
	fn path, spec for path, spec of invocationCache[hook]
	
	return
