$module.service 'socket', [
	'$q', '$rootScope', '$timeout'
	($q, $rootScope, $timeout) ->
		
		onMap = {}
		@on = (type, callback) -> (onMap[type] ?= []).push callback
		@stimulateOn = (type, data) ->
		
			defer = $q.defer()

			$timeout(
				->
					
					for callback in onMap[type] ?= []
						callback data
						
					defer.resolve()
						
				0
			)
			
			defer.promise
				
		emitMap = {}
		@catchEmit = (type, callback) ->
			
			defer = $q.defer()
			
			$timeout(
				->
					
					(emitMap[type] ?= []).push callback
					
					defer.resolve()
					
				0
			)
			
			defer.promise
			
		@emit = (type, data) ->
			
			for callback in emitMap[type] ?= []
				callback data
			
			return
		
		@stimulateUserLogin = (name, friends = {}, friendRequests = [], blocklist = []) ->
			
			@stimulateOn(
				'authorizationUpdate'
				status: 'authorized'
				user:
					name: name
					friends: friends
					friendRequests: friendRequests
					blocklist: blocklist
			)
		
		return
		
]
