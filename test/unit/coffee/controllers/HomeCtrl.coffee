describe 'HomeCtrl', ->
	
	homeCtrl = null
	$scope = null

	beforeEach ->
		
		inject ($controller, $location, $rootScope, title) ->
			
			$scope = $rootScope.$new()
			
			homeCtrl = $controller(
				'HomeCtrl'
				$location: $location
				$scope: $scope
				title: title
			)

	it 'should set page title to "Home"', ->
		
		inject (title) ->
			
			expect(title.page()).toBe 'Home'
