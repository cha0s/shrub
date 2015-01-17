angular.module(
  'shrub.config', ['shrub.require']
)

  .config(['shrub-requireProvider', function(requireProvider) {

    requireProvider.require('config').from({
      testMode: "unit",
      packageList: [
	"shrub-assets",
	"shrub-config",
	"shrub-core",
	"shrub-example",
	"shrub-http-express",
	"shrub-files",
	"shrub-form",
	"shrub-grunt",
	"shrub-html5-local-storage",
	"shrub-html5-notification",
	"shrub-http",
	"shrub-limiter",
	"shrub-logger",
	"shrub-nodemailer",
	"shrub-orm",
	"shrub-repl",
	"shrub-rpc",
	"shrub-schema",
	"shrub-skin",
	"shrub-skin-strapped",
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
