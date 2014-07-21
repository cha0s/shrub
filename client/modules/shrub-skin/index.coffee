
# # Skinning
# 
# Define skinning components.

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		'shrub-skin'
		(skin) ->
			
			skin.addStylesheets([
				'/lib/bootstrap/css/bootstrap.min.css'
				'/lib/bootstrap/css/bootstrap-theme.min.css'
				'/css/style.css'
			]).then -> skin.removeCloak()
			
	]
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$interval', '$q', '$window'
		($interval, $q, $window) ->
			
			service = {}
			
			service.addStylesheet = (href) ->
				
				deferred = $q.defer()
				
				poll = null

				styleSheets = $window.document.styleSheets
				index = styleSheets.length
				
				element = $window.document.createElement 'link'
				element.type = 'text/css'
				element.rel = 'stylesheet'
				element.href = href
				
				document.getElementsByTagName('head')[0].appendChild element
				
				resolve = ->
					
					$interval.cancel poll if poll?
					deferred.resolve()
				
				wasParsed = ->
					
					try

						styleSheet = styleSheets[index]
						
						return true if styleSheet.cssRules
						return true if styleSheet.rules?.length
					
					catch error
						
						return false
						
				# A rare case where IE actually does the right thing!
				# (and Opera).
				if not $window.opera and -1 is $window.navigator.userAgent.indexOf 'MSIE'
					
					poll = $interval (-> resolve() if wasParsed()), 10
				
				# Everyone else needs to resort to polling.
				else
				
					element.onload = resolve
					element.onreadystatechange = ->
						switch @readyState
							when 'loaded', 'complete'
								resolve()
					
				deferred.promise
			
			service.addStylesheets = (hrefs) ->
				$q.all (service.addStylesheet href for href in hrefs)
			
			service.removeCloak = ->
				angular.element('.shrub-skin-cloak').each ->
					$(this).removeClass 'shrub-skin-cloak'
			
			service
		
	]
