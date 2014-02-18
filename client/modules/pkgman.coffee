
invocationCache = {}
packageCache = null
_packages = []

exports.clearInvocationCache = (hook) ->
	
	if hook?
		invocationCache[hook] = null
	else
		invocationCache = {}
		
	return

exports.rebuildPackageCache = ->
	packageCache = {}
	
	for name in _packages
	
		# TODO only until I improve require()
		try
			package_ = require "packages/#{name}"
		catch error
			
			try
				package_ = require "packages/#{name}/index"
			catch error
				
				# Best course of action?
				continue
			
		packageCache[name] = package_
		
	return

exports.registerPackages = (packages) ->
	
	_packages.push.apply _packages, packages
	
	exports.rebuildPackageCache()

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
