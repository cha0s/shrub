
# Hook overview

Shrub implements message passing between packages through a hook system. Hooks
may be invoked with [pkgman.invoke()](/client/modules/pkgman.html), and are
implemented in packages by exporting `pkgmanRegister`.

For instance, if we are implementing a package and want to implement the
`preBootstrap` hook, our code would look like:

  exports.pkgmanRegister = (registrar) ->

    registrar.registerHook 'preBootstrap', ->

      # Your code goes here...

The list below was dynamically generated from the source code. There is a
description and a list of implementing packages for each hook.

<div class="hook-list">

Invoked in [client/app.coffee](./client/app.html):

* ## `appConfig`

   <h5>Invoked when the Angular application is in the configuration phase. </h5>

  * shrub-core (<a href="./packages/shrub-core/client/index.html#implementshookappconfig">client</a>)

  * shrub-example/home (<a href="./packages/shrub-example/client/home.html#implementshookappconfig">client</a>)

  * shrub-html5-local-storage (<a href="./packages/shrub-html5-local-storage/client/index.html#implementshookappconfig">client</a>)

  * shrub-html5-notification (<a href="./packages/shrub-html5-notification/client/index.html#implementshookappconfig">client</a>)

* ## `appRun`

   <h5>Invoked when the Angular application is run. </h5>

  * shrub-angular (<a href="./packages/shrub-angular/client/index.html#implementshookapprun">client</a>)

  * shrub-core (<a href="./packages/shrub-core/client/index.html#implementshookapprun">client</a>)

  * shrub-ui/window-title (<a href="./packages/shrub-ui/client/window-title.html#implementshookapprun">client</a>)

Invoked in [client/modules/errors.coffee](./client/modules/errors.html):

* ## `transmittableError`

   <h5>Allows packages to specify transmittable errors. Implementations should return a subclass of `TransmittableError`. </h5>

  * shrub-limiter (<a href="./packages/shrub-limiter/client/index.html#implementshooktransmittableerror">client</a>, <a href="./packages/shrub-limiter/index.html#implementshooktransmittableerror">server</a>)

  * shrub-user/login (<a href="./packages/shrub-user/client/login.html#implementshooktransmittableerror">client</a>, <a href="./packages/shrub-user/login.html#implementshooktransmittableerror">server</a>)

Invoked in [client/packages.coffee](./client/packages.html):

* ## `controller`

   <h5>Allows packages to define Angular controllers. Implementations should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation). </h5>

  * shrub-ui/list (<a href="./packages/shrub-ui/client/list/index.html#implementshookcontroller">client</a>)

  * shrub-ui/list/item (<a href="./packages/shrub-ui/client/list/item.html#implementshookcontroller">client</a>)

  * shrub-ui/menu (<a href="./packages/shrub-ui/client/menu.html#implementshookcontroller">client</a>)

  * shrub-ui/window-title (<a href="./packages/shrub-ui/client/window-title.html#implementshookcontroller">client</a>)

* ## `directive`

   <h5>Allows packages to define Angular directives. Implementations should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation). </h5>

  * shrub-form (<a href="./packages/shrub-form/client/index.html#implementshookdirective">client</a>)

  * shrub-form/widget/checkbox (<a href="./packages/shrub-form/client/widget/checkbox.html#implementshookdirective">client</a>)

  * shrub-form/widget/checkboxes (<a href="./packages/shrub-form/client/widget/checkboxes.html#implementshookdirective">client</a>)

  * shrub-form/widget/hidden (<a href="./packages/shrub-form/client/widget/hidden.html#implementshookdirective">client</a>)

  * shrub-form/widget/radio (<a href="./packages/shrub-form/client/widget/radio.html#implementshookdirective">client</a>)

  * shrub-form/widget/radios (<a href="./packages/shrub-form/client/widget/radios.html#implementshookdirective">client</a>)

  * shrub-form/widget/select (<a href="./packages/shrub-form/client/widget/select.html#implementshookdirective">client</a>)

  * shrub-form/widget/submit (<a href="./packages/shrub-form/client/widget/submit.html#implementshookdirective">client</a>)

  * shrub-form/widget/text (<a href="./packages/shrub-form/client/widget/text.html#implementshookdirective">client</a>)

  * shrub-skin-strapped/main-nav (<a href="./packages/shrub-skin-strapped/client/main-nav.html#implementshookdirective">client</a>)

  * shrub-ui/attributes (<a href="./packages/shrub-ui/client/attributes.html#implementshookdirective">client</a>)

  * shrub-ui/list (<a href="./packages/shrub-ui/client/list/index.html#implementshookdirective">client</a>)

  * shrub-ui/list/item (<a href="./packages/shrub-ui/client/list/item.html#implementshookdirective">client</a>)

  * shrub-ui/menu (<a href="./packages/shrub-ui/client/menu.html#implementshookdirective">client</a>)

  * shrub-ui/messages (<a href="./packages/shrub-ui/client/messages.html#implementshookdirective">client</a>)

  * shrub-ui/notifications (<a href="./packages/shrub-ui/client/notifications/index.html#implementshookdirective">client</a>)

  * shrub-ui/notifications/item (<a href="./packages/shrub-ui/client/notifications/item.html#implementshookdirective">client</a>)

  * shrub-ui/notifications/title (<a href="./packages/shrub-ui/client/notifications/title.html#implementshookdirective">client</a>)

  * shrub-ui/window-title (<a href="./packages/shrub-ui/client/window-title.html#implementshookdirective">client</a>)

  * shrub-user/email/forgot (<a href="./packages/shrub-user/client/email/forgot.html#implementshookdirective">client</a>)

  * shrub-user/email/register (<a href="./packages/shrub-user/client/email/register.html#implementshookdirective">client</a>)

* ## `augmentDirective`

   <h5>Allows packages to augment the directives defined by packages. One example is the automatic relinking functionality implemented by [shrub-skin](/packages/shrub-skin/client/index.html#implementshookaugmentdirective). </h5>

  * shrub-skin (<a href="./packages/shrub-skin/client/index.html#implementshookaugmentdirective">client</a>)

* ## `filter`

   <h5>Allows packages to define Angular filters. Implementations should return a function. </h5>

  * shrub-ui/markdown (<a href="./packages/shrub-ui/client/markdown.html#implementshookfilter">client</a>)

* ## `provider`

   <h5>Allows packages to define Angular providers. Implementations should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation). </h5>

  * shrub-html5-local-storage (<a href="./packages/shrub-html5-local-storage/client/index.html#implementshookprovider">client</a>)

  * shrub-html5-notification (<a href="./packages/shrub-html5-notification/client/index.html#implementshookprovider">client</a>)

  * shrub-skin (<a href="./packages/shrub-skin/client/index.html#implementshookprovider">client</a>)

* ## `service`

   <h5>Allows packages to define Angular services. Implementations should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation). </h5>

  * shrub-form (<a href="./packages/shrub-form/client/index.html#implementshookservice">client</a>)

  * shrub-orm (<a href="./packages/shrub-orm/client/index.html#implementshookservice">client</a>)

  * shrub-rpc (<a href="./packages/shrub-rpc/client/index.html#implementshookservice">client</a>)

  * shrub-socket (<a href="./packages/shrub-socket/client/index.html#implementshookservice">client</a>)

  * shrub-ui/messages (<a href="./packages/shrub-ui/client/messages.html#implementshookservice">client</a>)

  * shrub-ui/notifications (<a href="./packages/shrub-ui/client/notifications/index.html#implementshookservice">client</a>)

  * shrub-ui/window-title (<a href="./packages/shrub-ui/client/window-title.html#implementshookservice">client</a>)

  * shrub-user (<a href="./packages/shrub-user/client/index.html#implementshookservice">client</a>)

* ## `serviceMock`

   <h5>Allows packages to decorate mock Angular services. Implementations should return an [annotated function](http://docs.angularjs.org/guide/di#dependency-annotation). </h5>

Invoked in [packages/shrub-assets/index.coffee](./packages/shrub-assets/index.html):

* ## `assetMiddleware`

   <h5>Invoked to gather script assets for requests. </h5>

  * shrub-assets/angular (<a href="./packages/shrub-assets/angular.html#implementshookassetmiddleware">server</a>)

  * shrub-assets (<a href="./packages/shrub-assets/index.html#implementshookassetmiddleware">server</a>)

  * shrub-assets/jquery (<a href="./packages/shrub-assets/jquery.html#implementshookassetmiddleware">server</a>)

  * shrub-assets/ui-bootstrap (<a href="./packages/shrub-assets/ui-bootstrap.html#implementshookassetmiddleware">server</a>)

  * shrub-config (<a href="./packages/shrub-config/index.html#implementshookassetmiddleware">server</a>)

  * shrub-html5-local-storage (<a href="./packages/shrub-html5-local-storage/index.html#implementshookassetmiddleware">server</a>)

  * shrub-html5-notification (<a href="./packages/shrub-html5-notification/index.html#implementshookassetmiddleware">server</a>)

  * shrub-socket-socket.io (<a href="./packages/shrub-socket-socket.io/index.html#implementshookassetmiddleware">server</a>)

Invoked in [packages/shrub-audit/fingerprint.coffee](./packages/shrub-audit/fingerprint.html):

* ## `fingerprint`

   <h5>Allows a package to specify unique keys for this request, e.g. IP address, session ID, etc. Implementations take a request object as the only parameter. The request parameter may be null. </h5>

  * shrub-core (<a href="./packages/shrub-core/index.html#implementshookfingerprint">server</a>)

  * shrub-session (<a href="./packages/shrub-session/index.html#implementshookfingerprint">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookfingerprint">server</a>)

Invoked in [packages/shrub-config/index.coffee](./packages/shrub-config/index.html):

* ## `config`

   <h5>Allows packages to specify configuration that will be sent to the client. Implementations may return an object, or a promise that resolves to an object. </h5>

  * shrub-core (<a href="./packages/shrub-core/index.html#implementshookconfig">server</a>)

  * shrub-schema-rest (<a href="./packages/shrub-schema-rest/index.html#implementshookconfig">server</a>)

  * shrub-skin (<a href="./packages/shrub-skin/index.html#implementshookconfig">server</a>)

  * shrub-socket (<a href="./packages/shrub-socket/index.html#implementshookconfig">server</a>)

  * shrub-ui/notifications (<a href="./packages/shrub-ui/notifications.html#implementshookconfig">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookconfig">server</a>)

Invoked in [packages/shrub-core/client/index.coffee](./packages/shrub-core/client/index.html):

* ## `aHrefSanitizationWhilelist`

   <h5>Allow packages to define whitelisted patterns for ngHref attributes. </h5>

* ## `route`

   <h5>Allow packages to define routes in the Angular application. </h5>

  * shrub-example/about (<a href="./packages/shrub-example/client/about.html#implementshookroute">client</a>)

  * shrub-example/home (<a href="./packages/shrub-example/client/home.html#implementshookroute">client</a>)

  * shrub-user/forgot (<a href="./packages/shrub-user/client/forgot.html#implementshookroute">client</a>)

  * shrub-user/login (<a href="./packages/shrub-user/client/login.html#implementshookroute">client</a>)

  * shrub-user/logout (<a href="./packages/shrub-user/client/logout.html#implementshookroute">client</a>)

  * shrub-user/register (<a href="./packages/shrub-user/client/register.html#implementshookroute">client</a>)

  * shrub-user/reset (<a href="./packages/shrub-user/client/reset.html#implementshookroute">client</a>)

* ## `routeMock`

   <h5>Allow packages to define routes in the Angular application which are only defined during test mode. </h5>

  * shrub-core (<a href="./packages/shrub-core/client/index.html#implementshookroutemock">client</a>)

  * shrub-user/login (<a href="./packages/shrub-user/client/login.html#implementshookroutemock">client</a>)

* ## `routeAlter`

   <h5>Allow packages to alter defined routes. </h5>

* ## `routeControllerStart`

   <h5>Allow packages to act before a new route controller is executed. </h5>

  * shrub-ui/window-title (<a href="./packages/shrub-ui/client/window-title.html#implementshookroutecontrollerstart">client</a>)

Invoked in [packages/shrub-form/client/index.coffee](./packages/shrub-form/client/index.html):

* ## `formAlter`

   <h5></h5>

* ## `formFormIdAlter`

   <h5></h5>

* ## `formWidgets`

   <h5></h5>

  * shrub-form/widget/checkbox (<a href="./packages/shrub-form/client/widget/checkbox.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/checkboxes (<a href="./packages/shrub-form/client/widget/checkboxes.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/hidden (<a href="./packages/shrub-form/client/widget/hidden.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/radio (<a href="./packages/shrub-form/client/widget/radio.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/radios (<a href="./packages/shrub-form/client/widget/radios.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/select (<a href="./packages/shrub-form/client/widget/select.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/submit (<a href="./packages/shrub-form/client/widget/submit.html#implementshookformwidgets">client</a>)

  * shrub-form/widget/text (<a href="./packages/shrub-form/client/widget/text.html#implementshookformwidgets">client</a>)

Invoked in [packages/shrub-grunt/angular.coffee](./packages/shrub-grunt/angular.html):

* ## `angularCoreDependencies`

   <h5></h5>

  * shrub-html5-local-storage (<a href="./packages/shrub-html5-local-storage/index.html#implementshookangularcoredependencies">server</a>)

  * shrub-html5-notification (<a href="./packages/shrub-html5-notification/index.html#implementshookangularcoredependencies">server</a>)

Invoked in [packages/shrub-http/index.coffee](./packages/shrub-http/index.html):

* ## `httpRoutes`

   <h5>Allows packages to specify HTTP routes. Implementations should return an array of route specifications. See [shrub-orm-rest's implementation] (/packages/shrub-orm-rest/index.coffee#implementshookhttproutes) as an example. </h5>

  * shrub-example/about (<a href="./packages/shrub-example/about.html#implementshookhttproutes">server</a>)

  * shrub-schema-rest (<a href="./packages/shrub-schema-rest/index.html#implementshookhttproutes">server</a>)

Invoked in [packages/shrub-http/manager.coffee](./packages/shrub-http/manager.html):

* ## `httpInitializing`

   <h5>Invoked before the server is bound on the listening port. </h5>

  * shrub-http (<a href="./packages/shrub-http/index.html#implementshookhttpinitializing">server</a>)

  * shrub-socket (<a href="./packages/shrub-socket/index.html#implementshookhttpinitializing">server</a>)

* ## `httpMiddleware`

   <h5>Invoked every time an HTTP connection is established. </h5>

  * shrub-angular (<a href="./packages/shrub-angular/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-audit (<a href="./packages/shrub-audit/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-config (<a href="./packages/shrub-config/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-core (<a href="./packages/shrub-core/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-form (<a href="./packages/shrub-form/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-http-express/errors (<a href="./packages/shrub-http-express/errors.html#implementshookhttpmiddleware">server</a>)

  * shrub-http-express/logger (<a href="./packages/shrub-http-express/logger.html#implementshookhttpmiddleware">server</a>)

  * shrub-http-express/routes (<a href="./packages/shrub-http-express/routes.html#implementshookhttpmiddleware">server</a>)

  * shrub-http-express/session (<a href="./packages/shrub-http-express/session.html#implementshookhttpmiddleware">server</a>)

  * shrub-http-express/static (<a href="./packages/shrub-http-express/static.html#implementshookhttpmiddleware">server</a>)

  * shrub-http (<a href="./packages/shrub-http/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-skin (<a href="./packages/shrub-skin/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookhttpmiddleware">server</a>)

  * shrub-villiany (<a href="./packages/shrub-villiany/index.html#implementshookhttpmiddleware">server</a>)

Invoked in [packages/shrub-orm/client/index.coffee](./packages/shrub-orm/client/index.html):

* ## `collections`

   <h5>Allows packages to create Waterline collections. </h5>

  * shrub-limiter (<a href="./packages/shrub-limiter/index.html#implementshookcollections">server</a>)

  * shrub-session (<a href="./packages/shrub-session/index.html#implementshookcollections">server</a>)

  * shrub-ui/notifications (<a href="./packages/shrub-ui/notifications.html#implementshookcollections">server</a>)

  * shrub-user (<a href="./packages/shrub-user/client/index.html#implementshookcollections">client</a>, <a href="./packages/shrub-user/index.html#implementshookcollections">server</a>)

  * shrub-villiany (<a href="./packages/shrub-villiany/index.html#implementshookcollections">server</a>)

* ## `collectionsAlter`

   <h5>Allows packages to alter any Waterline collections defined. </h5>

  * shrub-orm (<a href="./packages/shrub-orm/client/index.html#implementshookcollectionsalter">client</a>)

  * shrub-user (<a href="./packages/shrub-user/client/index.html#implementshookcollectionsalter">client</a>, <a href="./packages/shrub-user/index.html#implementshookcollectionsalter">server</a>)

Invoked in [packages/shrub-orm/index.coffee](./packages/shrub-orm/index.html):

* ## `collections`

   <h5>Allows packages to create Waterline collections. </h5>

  * shrub-limiter (<a href="./packages/shrub-limiter/index.html#implementshookcollections">server</a>)

  * shrub-session (<a href="./packages/shrub-session/index.html#implementshookcollections">server</a>)

  * shrub-ui/notifications (<a href="./packages/shrub-ui/notifications.html#implementshookcollections">server</a>)

  * shrub-user (<a href="./packages/shrub-user/client/index.html#implementshookcollections">client</a>, <a href="./packages/shrub-user/index.html#implementshookcollections">server</a>)

  * shrub-villiany (<a href="./packages/shrub-villiany/index.html#implementshookcollections">server</a>)

* ## `collectionsAlter`

   <h5>Allows packages to alter any Waterline collections defined. </h5>

  * shrub-orm (<a href="./packages/shrub-orm/client/index.html#implementshookcollectionsalter">client</a>)

  * shrub-user (<a href="./packages/shrub-user/client/index.html#implementshookcollectionsalter">client</a>, <a href="./packages/shrub-user/index.html#implementshookcollectionsalter">server</a>)

Invoked in [packages/shrub-repl/index.coffee](./packages/shrub-repl/index.html):

* ## `replContext`

   <h5>Allow packages to add values to the REPL's context. </h5>

  * shrub-core (<a href="./packages/shrub-core/index.html#implementshookreplcontext">server</a>)

  * shrub-install (<a href="./packages/shrub-install/index.html#implementshookreplcontext">server</a>)

  * shrub-orm (<a href="./packages/shrub-orm/index.html#implementshookreplcontext">server</a>)

  * shrub-socket (<a href="./packages/shrub-socket/index.html#implementshookreplcontext">server</a>)

  * shrub-user/register (<a href="./packages/shrub-user/register.html#implementshookreplcontext">server</a>)

Invoked in [packages/shrub-rpc/index.coffee](./packages/shrub-rpc/index.html):

* ## `endpoint`

   <h5>Gather all endpoints. </h5>

  * shrub-angular (<a href="./packages/shrub-angular/index.html#implementshookendpoint">server</a>)

  * shrub-ui/notifications (<a href="./packages/shrub-ui/notifications.html#implementshookendpoint">server</a>)

  * shrub-user/forgot (<a href="./packages/shrub-user/forgot.html#implementshookendpoint">server</a>)

  * shrub-user/login (<a href="./packages/shrub-user/login.html#implementshookendpoint">server</a>)

  * shrub-user/logout (<a href="./packages/shrub-user/logout.html#implementshookendpoint">server</a>)

  * shrub-user/register (<a href="./packages/shrub-user/register.html#implementshookendpoint">server</a>)

  * shrub-user/reset (<a href="./packages/shrub-user/reset.html#implementshookendpoint">server</a>)

* ## `endpointAlter`

   <h5>Allows packages to modify any endpoints defined. </h5>

  * shrub-limiter (<a href="./packages/shrub-limiter/index.html#implementshookendpointalter">server</a>)

  * shrub-villiany (<a href="./packages/shrub-villiany/index.html#implementshookendpointalter">server</a>)

* ## `endpointFinished`

   <h5>Allow packages to act after an RPC call, but before the response is sent. Packages may modify the response before it is returned. Implementations should return a promise. When all promises are resolved, the result is returned. </h5>

  * shrub-session (<a href="./packages/shrub-session/index.html#implementshookendpointfinished">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookendpointfinished">server</a>)

Invoked in [packages/shrub-socket/manager.coffee](./packages/shrub-socket/manager.html):

* ## `socketAuthorizationMiddleware`

   <h5>Invoked when a socket connection begins. Packages may throw an instance of `SocketManager.AuthorizationFailure` to reject the socket connection as unauthorized. </h5>

  * shrub-audit (<a href="./packages/shrub-audit/index.html#implementshooksocketauthorizationmiddleware">server</a>)

  * shrub-core (<a href="./packages/shrub-core/index.html#implementshooksocketauthorizationmiddleware">server</a>)

  * shrub-http-express/session (<a href="./packages/shrub-http-express/session.html#implementshooksocketauthorizationmiddleware">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshooksocketauthorizationmiddleware">server</a>)

  * shrub-villiany (<a href="./packages/shrub-villiany/index.html#implementshooksocketauthorizationmiddleware">server</a>)

* ## `socketConnectionMiddleware`

   <h5>Invoked for every socket connection. </h5>

  * shrub-rpc (<a href="./packages/shrub-rpc/index.html#implementshooksocketconnectionmiddleware">server</a>)

  * shrub-session (<a href="./packages/shrub-session/index.html#implementshooksocketconnectionmiddleware">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshooksocketconnectionmiddleware">server</a>)

* ## `socketDisconnectionMiddleware`

   <h5>Invoked when a socket disconnects. </h5>

Invoked in [packages/shrub-user/login.coffee](./packages/shrub-user/login.html):

* ## `userBeforeLoginMiddleware`

   <h5>Invoked before a user logs in. </h5>

* ## `userAfterLoginMiddleware`

   <h5>Invoked after a user logs in. </h5>

Invoked in [packages/shrub-user/logout.coffee](./packages/shrub-user/logout.html):

* ## `userBeforeLogoutMiddleware`

   <h5>Invoked before a user logs out. </h5>

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookuserbeforelogoutmiddleware">server</a>)

* ## `userAfterLogoutMiddleware`

   <h5>Invoked after a user logs out. </h5>

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookuserafterlogoutmiddleware">server</a>)

Invoked in [server/config.coffee](./server/config.html):

* ## `packageSettings`

   <h5>Invoked when the server application is loading configuration. Allows packages to define their own default settings. </h5>

  * shrub-angular (<a href="./packages/shrub-angular/index.html#implementshookpackagesettings">server</a>)

  * shrub-assets (<a href="./packages/shrub-assets/index.html#implementshookpackagesettings">server</a>)

  * shrub-core (<a href="./packages/shrub-core/index.html#implementshookpackagesettings">server</a>)

  * shrub-http (<a href="./packages/shrub-http/index.html#implementshookpackagesettings">server</a>)

  * shrub-nodemailer (<a href="./packages/shrub-nodemailer/index.html#implementshookpackagesettings">server</a>)

  * shrub-orm (<a href="./packages/shrub-orm/index.html#implementshookpackagesettings">server</a>)

  * shrub-repl (<a href="./packages/shrub-repl/index.html#implementshookpackagesettings">server</a>)

  * shrub-schema-rest (<a href="./packages/shrub-schema-rest/index.html#implementshookpackagesettings">server</a>)

  * shrub-session (<a href="./packages/shrub-session/index.html#implementshookpackagesettings">server</a>)

  * shrub-skin (<a href="./packages/shrub-skin/index.html#implementshookpackagesettings">server</a>)

  * shrub-socket (<a href="./packages/shrub-socket/index.html#implementshookpackagesettings">server</a>)

  * shrub-user (<a href="./packages/shrub-user/index.html#implementshookpackagesettings">server</a>)

</div>
