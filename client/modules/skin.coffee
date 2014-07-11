
config = require 'config'

exports.registerDirective = (uri) ->

	compile: (scope, element) ->
		
		angular.element(element).injector().invoke [
			'$compile', '$http'
			($compile, $http) ->
				
				do relink = ->
					return unless skinKey = config.get 'shrub:skin:key'
					
					element.hide()
					
					promise = $http.get "/skin/#{skinKey}/#{uri}"
					
					promise.success (data, status, headers, config) ->
						
						element.html data
						$compile(element.contents())(scope)
						
					promise.finally -> element.show()
					
				scope.$on 'shrub.skin.update', relink
				
		]
