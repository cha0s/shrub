angular.module(
  'shrub.config', ['shrub.require']
)

  .config(['shrub-requireProvider', function(requireProvider) {

    requireProvider.require('config').from({
      testMode: "unit",
      packageList: [
        "shrub-angular",
        "shrub-assets",
        "shrub-config",
        "shrub-core",
        "shrub-example",
        "shrub-http-express",
        "shrub-files",
        "shrub-form",
        "shrub-http",
        "shrub-limiter",
        "shrub-logger",
        "shrub-nodemailer",
        "shrub-repl",
        "shrub-rpc",
        "shrub-schema",
        "shrub-skin",
        "shrub-session",
        "shrub-socket",
        "shrub-socket-socket.io",
        "shrub-ui",
        "shrub-user",
        "shrub-villiany"
      ],
      "packageConfig": {
        "shrub-core": {
          siteName: "Shrub"
        },
        "shrub-socket": {
          manager: {
            module: "shrub-socket/dummy"
          }
        },      
        "shrub-user": {
          name: "Anonymous",
          email: null
        }
      }
    });

  }]);
