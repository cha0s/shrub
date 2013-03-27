describe 'WindowTitleCtrl', ->
	
	windowTitleCtrl = null
	$scope = null

	beforeEach ->
		
		inject ($controller, $rootScope, title) ->
		
			$scope = $rootScope.$new()
		
			windowTitleCtrl = $controller(
				'WindowTitleCtrl'
				$scope: $scope
				title: title
			)

	it 'should set $scope.title to the title service', ->
		
		inject (title) ->
			
			expect($scope.title).toBe title.window
