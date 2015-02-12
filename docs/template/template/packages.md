
# Package overview

Packages are how Shrub organizes functionality. Packages may be provided for
the server or the client (or both).

This page provides a listing of packages in this project, along with a short
description of the functionality they provide.


##Client-side

* ### [`shrub-angular`](./packages/shrub-angular/client/index.html)

   <h4>Hang up any sandbox if we don't need it anymore.</h4>

* ### [`shrub-core`](./packages/shrub-core/client/index.html)

   <h4>Core functionality.</h4>

* ### [`shrub-example`](./packages/shrub-example/client/index.html)

   <h4>Define some routes, show some stuff off!</h4>

* ### [`shrub-form`](./packages/shrub-form/client/index.html)

   <h4>Define a directive for Angular forms, and a service to cache and look them up later.</h4>

* ### [`shrub-html5-local-storage`](./packages/shrub-html5-local-storage/client/index.html)

   <h4></h4>

* ### [`shrub-html5-notification`](./packages/shrub-html5-notification/client/index.html)

   <h4></h4>

* ### [`shrub-limiter`](./packages/shrub-limiter/client/index.html)

   <h4>Define a TransmittableError for the limiter.</h4>

* ### [`shrub-orm`](./packages/shrub-orm/client/index.html)

   <h4>browserify -r waterline-browser -x util -x assert -x events -x bluebird -x async -x lodash -x buffer -x anchor -x validator -x waterline-criteria -x waterline-schema > waterline-browser.js</h4>

* ### [`shrub-rpc`](./packages/shrub-rpc/client/index.html)

   <h4>Define an Angular service to issue [remote procedure calls](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing).</h4>

* ### [`shrub-skin`](./packages/shrub-skin/client/index.html)

   <h4>Define skinning components.</h4>

* ### [`shrub-skin-strapped`](./packages/shrub-skin-strapped/client/index.html)

   <h4></h4>

* ### [`shrub-socket`](./packages/shrub-socket/client/index.html)

   <h4>Provide an Angular service wrapping a real-time socket.</h4>

* ### [`shrub-socket-socket.io`](./packages/shrub-socket-socket.io/client/index.html)

   <h4>Provide an Angular service wrapping Socket.IO.</h4>

* ### [`shrub-ui`](./packages/shrub-ui/client/index.html)

   <h4>Define user interface components.</h4>

* ### [`shrub-user`](./packages/shrub-user/client/email/index.html)

   <h4></h4>

##Server-side

* ### [`shrub-angular`](./packages/shrub-angular/index.html)

   <h4>A sandboxed version of Angular, for clients lacking JS.</h4>

* ### [`shrub-assets`](./packages/shrub-assets/index.html)

   <h4>Serve different JS based on whether the server is running in production mode.</h4>

* ### [`shrub-audit`](./packages/shrub-audit/index.html)

   <h4></h4>

* ### [`shrub-config`](./packages/shrub-config/index.html)

   <h4>Client-side configuration.</h4>

* ### [`shrub-core`](./packages/shrub-core/index.html)

   <h4>Implements various core functionality.</h4>

* ### [`shrub-example`](./packages/shrub-example/index.html)

   <h4></h4>

* ### [`shrub-form`](./packages/shrub-form/index.html)

   <h4>Handle form and method parsing, and submission of POST'ed data into the Angular sandbox.</h4>

* ### [`shrub-grunt`](./packages/shrub-grunt/dox/index.html)

   <h4></h4>

* ### [`shrub-html5-local-storage`](./packages/shrub-html5-local-storage/index.html)

   <h4></h4>

* ### [`shrub-html5-notification`](./packages/shrub-html5-notification/index.html)

   <h4></h4>

* ### [`shrub-http`](./packages/shrub-http/index.html)

   <h4>Manage HTTP connections.</h4>

* ### [`shrub-http-express`](./packages/shrub-http-express/index.html)

   <h4>An [Express](http://expressjs.com/) HTTP server implementation, with middleware for sessions, routing, logging, etc.</h4>

* ### [`shrub-install`](./packages/shrub-install/index.html)

   <h4></h4>

* ### [`shrub-limiter`](./packages/shrub-limiter/index.html)

   <h4>Limits the rate at which clients can do certain operations, like call RPC endpoints.</h4>

* ### [`shrub-nodemailer`](./packages/shrub-nodemailer/index.html)

   <h4>Renders and sends email.</h4>

* ### [`shrub-orm`](./packages/shrub-orm/index.html)

   <h4>Tools for working with [Waterline](https://github.com/balderdashy/waterline).</h4>

* ### [`shrub-repl`](./packages/shrub-repl/index.html)

   <h4>Runs a REPL and allows packages to add values to its context.</h4>

* ### [`shrub-rpc`](./packages/shrub-rpc/index.html)

   <h4>Framework for communication between client and server through [RPC](http://en.wikipedia.org/wiki/Remote_procedure_call#Message_passing)</h4>

* ### [`shrub-schema-rest`](./packages/shrub-schema-rest/index.html)

   <h4>Serve the database schema over a REST API.</h4>

* ### [`shrub-session`](./packages/shrub-session/index.html)

   <h4>Various means for dealing with sessions.</h4>

* ### [`shrub-skin`](./packages/shrub-skin/index.html)

   <h4>Allows the visual aspects of the site to be controlled by skin packages.</h4>

* ### [`shrub-skin-strapped`](./packages/shrub-skin-strapped/index.html)

   <h4>The default skin.</h4>

* ### [`shrub-socket`](./packages/shrub-socket/index.html)

   <h4>Manage socket connections.</h4>

* ### [`shrub-socket-socket.io`](./packages/shrub-socket-socket.io/index.html)

   <h4>SocketManager implementation using [Socket.IO](http://socket.io/).</h4>

* ### [`shrub-ui`](./packages/shrub-ui/index.html)

   <h4></h4>

* ### [`shrub-user`](./packages/shrub-user/index.html)

   <h4>User operations.</h4>

* ### [`shrub-villiany`](./packages/shrub-villiany/index.html)

   <h4>Watch for and punish bad behavior.</h4>
