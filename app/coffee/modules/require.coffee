# Implement require in the spirit of NodeJS.

angular.module('Shrub.require', [])
	
	.factory 'require', ->
	
		require = (name) ->
	
			throw new Error "Module #{name} not found!" unless requires_[name]?
			
			unless requires_[name].module?
				exports = {}
				module = exports: exports
				
				f = requires_[name]
				requires_[name] = module: module
				
				f.call null, module, exports, require
				
			requires_[name].module.exports
