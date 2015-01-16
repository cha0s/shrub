
# # About page

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `route`
	registrar.registerHook 'route', ->
	
		path: 'about'
		title: 'About'
		
		controller: [
			'$http', '$scope'
			($http, $scope) ->
				
				$http.get('/shrub-example/about/README.md').success((data) ->
					$scope.about = data
				).finally -> $scope.$emit 'shrubFinishedRendering' 
				
		]
		
		template: """
	
<span
	class="about"
	data-ng-bind-html="about | shrubUiMarkdown:false"
></span>
	
"""
	
