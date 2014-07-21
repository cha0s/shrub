
config = require 'config'

exports.registerDirective = (uri) ->

	compile: (scope, element) ->
		
		angular.element(element).injector().invoke [
			'$compile', '$http'
			($compile, $http) ->
				
				do relink = ->
					return unless skinKey = config.get 'skin:default'
					
					wasVisible = element.is ':visible'
					
					promise = $http.get "/skin/#{skinKey}/#{uri}"
					
					promise.success (data, status, headers, config) ->
					
						element.hide() if wasVisible
						element.html data
						$compile(element.contents())(scope)
						
					promise.finally -> element.show() if wasVisible
					
				scope.$on 'shrub.skin.update', relink
				
		]
