angular.module('shrub.config', []).provider('config', function() {

	var _config = {
		testMode: 'unit',
		packageList: [
			"core",
			"example",
			"form",
			"rpc",
			"schema",
			"socket",
			"ui",
			"user"
		],
		user: {
			"name": "Anonymous"
		}
	};
	
	var get = function(key) { return _config[key]; };
	var has = function(key) { return _config[key] != null; };
	var set = function(key, value) { return _config[key] = value; };
	
	return {
		
		get: get,
		has: has,
		set: set,
		
		$get: function() { return {get: get, has: has, set: set}; }
	};
	
});
