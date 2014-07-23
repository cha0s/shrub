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
        "shrub-express",
        "shrub-files",
        "shrub-form",
        "shrub-limiter",
        "shrub-logger",
        "shrub-nodemailer",
        "shrub-repl",
        "shrub-rpc",
        "shrub-schema",
        "shrub-session",
        "shrub-socket",
        "shrub-ui",
        "shrub-user",
        "shrub-villiany"
      ],
      siteName: "Shrub",
      "shrub-socket": {
        manager: {
          module: "shrub-socket/dummy"
        }
      },      
      user: {
        name: "Anonymous",
        email: null
      }
    });

  }]);
