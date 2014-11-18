
describe 'rpc', ->
	
	rpc = null
	
	beforeEach ->
		
		inject [
			'shrub-rpc'
			(_rpc_) -> rpc = _rpc_
		]
		
	it 'should send and receive data back from rpc calls', ->

		inject [
			'$rootScope', '$timeout', 'shrub-socket'
			($rootScope, $timeout, socket) ->
				
				socket.catchEmit 'rpc://test', (data, fn) -> fn result: 420
				
				result = null
				error = 'invalid'
				
				promise = rpc.call 'test'
				promise.then (_) -> result = _
				promise.catch (_) -> error = _
				
				$timeout.flush()
				$rootScope.$apply()
				
				expect(result).toBe 420
				expect(error).toBe 'invalid'
		]
		
	it 'should handle errors gracefully', ->

		inject [
			'$rootScope', 'shrub-socket'
			($rootScope, socket) ->
				
				socket.catchEmit 'rpc://test', (data, fn) ->
					fn error: new Error()
					
				result = 'invalid'
				error = null
				
				promise = rpc.call 'test'
				promise.then (_) -> result = _
				promise.catch (_) -> error = _
					
				$rootScope.$apply()
				
				expect(result).toBe 'invalid'
				expect(error).toBeDefined()
				
		]
		