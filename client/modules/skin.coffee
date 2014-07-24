
config = require 'config'

cache = null

exports.registerDirective = ($injector, uri) ->

	compile: (scope, element) ->
		
		$injector.invoke [
			'$cacheFactory', '$compile', '$http'
			($cacheFactory, $compile, $http) ->
				
				cache = $cacheFactory 'shrub-skin' unless cache?
				
				do relink = ->
					return unless skinKey = config.get 'packageConfig:shrub-skin:default'
					
					wasVisible = element.is ':visible'
					
					resolve = (data) ->
					
						element.hide() if wasVisible
						element.html data
						$compile(element.contents())(scope)

					if (promise = cache.get "#{skinKey}/#{uri}")
						
						promise.success resolve
						element.show() if wasVisible
					
					else
					
						promise = $http.get "/skin/#{skinKey}/#{uri}"
						cache.put "#{skinKey}/#{uri}", promise
						
						promise.success (data, status, headers, config) ->
							
							resolve data
							
						promise.finally -> element.show() if wasVisible
					
				scope.$on 'shrub.skin.update', relink
				
		]
