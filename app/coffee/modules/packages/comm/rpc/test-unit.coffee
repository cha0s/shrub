
describe 'rpc', ->
	
	rpc = null
	
	beforeEach ->
		
		inject [
			'comm/rpc'
			(_rpc_) -> rpc = _rpc_
		]
		
	it 'should send and receive data back from rpc calls', ->

		inject [
			'$rootScope', 'comm/socket'
			($rootScope, socket) ->
				
				socket.catchEmit 'rpc://test', (data, fn) -> fn result: 420
				
				promise = rpc.call 'test'
				promise.then (result) -> expect(result).toBe 420
				promise.catch (errors) -> expect(true).toBe false
				
				$rootScope.$apply()
		]
		
		
	it 'should handle errors gracefully', (done) ->

		inject [
			'$rootScope', 'comm/socket'
			($rootScope, socket) ->
				
				socket.catchEmit 'rpc://test', (data, fn) ->
					fn errors: [code: 420]
					
				promise = rpc.call 'test'
				promise.then (result) -> expect(true).toBe false
				promise.catch (error) -> expect(error).toBeDefined()
					
				$rootScope.$apply()
		]
		
		