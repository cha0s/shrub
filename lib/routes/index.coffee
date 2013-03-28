
module.exports = (app) ->
	
# The main entry point.
	for resourcePath in [
		'/'
		
# For testacular.
		'/app/index.html'
	]
		app.get resourcePath, (req, res) ->
			res.render 'index',
				config: JSON.stringify req.config
	
