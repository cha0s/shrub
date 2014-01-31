
exports.$httpInitializer = (req, res, next) ->
	
	req.http.listen next
