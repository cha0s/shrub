
# # Angular
# 
# Hang up any sandbox if we don't need it anymore.

# ## Implements hook `appRun`
exports.$appRun = -> [
	'$window', 'rpc'
	($window, {call}) ->
	
		# Hang up the socket unless it's the local (Node.js) client.
		call 'hangup' unless $window.navigator.userAgent.match /^Node\.js .*$/

]
