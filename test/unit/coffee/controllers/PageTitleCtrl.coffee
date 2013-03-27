describe 'PageTitleCtrl', ->
	
	pageTitleCtrl = null
	$scope = null

	beforeEach ->
		
		inject ($controller, $rootScope, title) ->
			
			$scope = $rootScope.$new()
		
			pageTitleCtrl = $controller(
				'PageTitleCtrl'
				$scope: $scope
				title: title
			)

	it 'should set $scope.title to the title service', ->
		
		inject (title) ->
			
			expect($scope.title).toBe title.page
