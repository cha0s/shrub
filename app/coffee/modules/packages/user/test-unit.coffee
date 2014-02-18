
describe 'user', ->
	
	user = null
	
	beforeEach ->
		
		inject (_user_) -> user = _user_
		
	it 'should provide an anonymous user by default', ->
		
		inject [
			'$rootScope', '$timeout'
			($rootScope, $timeout) ->
				
				userIsLoggedIn = false
				
				user.load().then (user) -> userIsLoggedIn = user.id?
				
				$timeout.flush()
				$rootScope.$apply()
				
				expect(userIsLoggedIn).toBe false

		]

	it 'should log in a user through RPC', ->
		
		inject [
			'$rootScope', '$timeout', 'comm/socket'
			($rootScope, $timeout, socket) ->
				
				userIsLoggedIn = false
				
				socket.catchEmit 'rpc://user.login', (data, fn) ->
					fn result: id: 1, name: 'cha0s'
				
				(user.login 'local', 'cha0s', 'password').then ->
					user.load().then (user) -> userIsLoggedIn = user.id?
				
				$timeout.flush()
				$rootScope.$apply()
				
				expect(userIsLoggedIn).toBe true
			
		]

	it 'should log out a user through RPC', ->
		
		inject [
			'$rootScope', '$timeout', 'comm/socket'
			($rootScope, $timeout, socket) ->
				
				userIsLoggedIn = true
				
				socket.catchEmit 'rpc://user.login', (data, fn) ->
					fn result: id: 1, name: 'cha0s'
				
				socket.catchEmit 'rpc://user.logout', (data, fn) ->
					fn result: null
				
				(user.login 'local', 'cha0s', 'password').then ->
					user.logout().then ->
						user.load().then (user) -> userIsLoggedIn = user.id?
				
				$timeout.flush()
				$rootScope.$apply()
				
				expect(userIsLoggedIn).toBe false
			
		]
