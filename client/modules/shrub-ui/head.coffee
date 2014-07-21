
# Head contents.

exports.pkgmanRegister = (registrar) ->
	
	# ## Implements hook `directive`
	registrar.registerHook 'directive', -> [
		
		->
			
			restrict: 'EACM'
			transclude: true
			
			template: """

<title data-shrub-ui-title data-ng-bind="windowTitle"></title>

<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no">

<link rel="shortcut icon" href="/favicon.ico" />

<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap.min.css"></link>
<link rel="stylesheet" href="/lib/bootstrap/css/bootstrap-theme.min.css"></link>

<link rel="stylesheet" href="/css/style.css"></link>

"""
		
	]
	
