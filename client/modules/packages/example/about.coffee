
exports.$route = ->

	path: 'about'
	title: 'About'
	
	controller: [
		'$scope'
		($scope) ->
			
			$scope.about = """
Shrub
=====

Shrub is a JavaScript (or CoffeeScript if you prefer) application
framework. [AngularJS](http://angularjs.org/) is used on the client-side, as
well as [Socket.IO](http://socket.io/), enabling real-time communication right
out of the box. The server is a [Node.js](http://nodejs.org/) server using
[Redis](http://redis.io/) for persistence and scalability.

Shrub handles generation (using [Grunt](http://gruntjs.com/)) of the vast
majority of Angular boilerplate, to allow you to structure your application in
a very clean and consistent way.

Also provided is an Angular service providing a NodeJS-style module framework
to allow your application to bridge the gap between Angular and the vast
ecosystem of publically available NodeJS-style modules.

### The Twist

JS applications catch flak because they are not impliticly SEO-friendly,
as well as requiring JS execution, which [some people prefer not to
allow for untrusted websites](http://www.wired.com/threatlevel/2013/09/freedom-hosting-fbi/).

Shrub does an interesting thing which is possible because both sides of the
stack have fully featured JS ([well, except for certain older browsers...](http://www.youtube.com/watch?v=lD9FAOPBiDk)).
When a client requests a page from Shrub, it spins up a DOM for the request,
and renders the entire page, JS and all. Shrub then serves the fully-built page
to the client.

If the client has JS enabled, the client-side Angular application takes over
from here, loading new pages (nearly) instantly and generally benefitting from
all the lovely things that client-side applications offer.

However, if the client does not have JS enabled, a new page will hit the server
again, and Shrub, crafty as it is, will reuse the DOM created for that session,
navigate Angular to the new page, render it, and serve it to the client. Nice! 

### Get rolling

* Get yourself a clone: `$ git clone git://github.com/cha0s/shrub.git`

* Get in the new directory and then the usual `npm install`, followed by
`$ scripts/good-to-go`. This script will return 0 if the project builds, and
the tests run successfully. In other words, you can easily wire it up in a
pre-commit hook.

* Spin up the server: `$ npm start` and navigate to http://localhost:4201 (make
sure you've run grunt at least once!)

* Check out how Shrub has generated a lot of Angular boilerplate for
you. Particularly app/js/{controllers,directives,filters,services}.js will
be of interest.

### TODO

There is much to do, and this project is currently essentially a
proof-of-concept of some of the ideas outlined here. My plans for this
framework include:

* Integration of a database abstraction layer
* A resource layer (using the aforementioned db layer) for serving Angular $resource requests
* Socket/Session stores based on aforementioned db layer
* Better handling of server-side DOM in the absence of a session/cookie
* Research into whether server-side rendering can be synchronized in a DRY fashion (currently the rendering is given 50 ms to complete, not ideal)
* Better abstraction of assets, instead of (for instance) hardcoding bootstrap/LESS
* Using standardized solutions to UI and Bootstrap interface, instead of the hackish half-hand-rolled solutions currently in place
* Better abstraction of the RPC interface, allowing other systems beside Socket.IO
* Research into whether the http server interface (currently using Express) is worth abstracting
* There is a rudimentary working form API, but research should be done as to how to DRY it up and make sure it's secure and resistant to attack
"""
	
			$scope.$emit 'shrubFinishedRendering'
	]
	
	template: """

<span
	class="about"
	data-ng-bind-html="about | uiMarkdown:false"
></span>

"""

