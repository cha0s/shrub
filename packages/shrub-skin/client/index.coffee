
# # Skinning
# 
# Define skinning components.

config = require 'config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `appRun`
	registrar.registerHook 'appRun', -> [
		'$http', 'shrub-skin'
		($http, skin) ->
			
			skin.change config.get 'packageConfig:shrub-skin:default'
			
	]
	
	# ## Implements hook `service`
	registrar.registerHook 'service', -> [
		'$http', '$interval', '$q', '$window'
		($http, $interval, $q, $window) ->
			
			service = {}
			
			service.addStylesheet = (href) ->
				
				deferred = $q.defer()
				
				styleSheets = $window.document.styleSheets
				index = styleSheets.length
				
				element = $window.document.createElement 'link'
				element.type = 'text/css'
				element.rel = 'stylesheet'
				element.href = href
				document.getElementsByTagName('head')[0].appendChild element
				
				resolve = -> deferred.resolve element
				
				wasParsed = ->
					
					try

						styleSheet = styleSheets[index]
						
						return true if styleSheet.cssRules
						return true if styleSheet.rules?.length
					
					catch error
						
						return false
						
				# A rare case where IE actually does the right thing!
				# (and Opera).
				if $window.opera or -1 isnt $window.navigator.userAgent.indexOf 'MSIE'
					
					element.onload = resolve
					element.onreadystatechange = ->
						switch @readyState
							when 'loaded', 'complete'
								resolve()
					
				# Everyone else needs to resort to polling.
				else
				
					poll = $interval(
						->
							if wasParsed()
								$interval.cancel poll
								resolve()
						10
					)
				
				deferred.promise
			
			service.addStylesheets = (hrefs) ->
				$q.all (service.addStylesheet href for href in hrefs)
			
			currentSkin = null
			
			service.change = (key) ->
				
				if currentSkin?
					
					for link in currentSkin.links
						link.parentNode.removeChild link
				
				if key
					
					currentSkin = links: []
				
					promise = $http.get "/skin/#{key}/index.json"
					
					promise.success (data) ->
						
						stylesheets = data.stylesheets ? []
						
						service.addStylesheets(stylesheets).then (links) ->
							
							currentSkin.links = links
							
							service.removeCloak()
							
					promise.error -> service.removeCloak()
					
				else
					
					currentSkin = null
				
					service.removeCloak()
			
			service.removeCloak = ->
				angular.element('.shrub-skin-cloak').each ->
					$(this).removeClass 'shrub-skin-cloak'
			
			service
		
	]
