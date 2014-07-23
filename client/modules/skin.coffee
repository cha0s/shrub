
config = require 'config'

exports.registerDirective = (uri) ->

	compile: (scope, element) ->
		
		# Hack for unit testing, not sure the "right" way to do this.
		injector = if inject?
			inject
		else
			injector = angular.element(element).injector()
			injector.invoke.bind injector
		
		injector [
			'$compile', '$http'
			($compile, $http) ->
				
				do relink = ->
					return unless skinKey = config.get 'packageConfig:shrub-skin:default'
					
					wasVisible = element.is ':visible'
					
					promise = $http.get "/skin/#{skinKey}/#{uri}"
					
					promise.success (data, status, headers, config) ->
					
						element.hide() if wasVisible
						element.html data
						$compile(element.contents())(scope)
						
					promise.finally -> element.show() if wasVisible
					
				scope.$on 'shrub.skin.update', relink
				
		]
