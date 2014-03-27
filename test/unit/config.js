angular.module(
  'shrub.config', ['shrub.require']
)

  .config(['requireProvider', function(requireProvider) {

    requireProvider.require('config').from({
      testMode: "unit",
      packageList: [
        "angular",
        "assets",
        "config",
        "core",
        "example",
        "express",
        "files",
        "form",
        "limiter",
        "logger",
        "nodemailer",
        "repl",
        "rpc",
        "schema",
        "session",
        "socket",
        "ui",
        "user",
        "villiany"
      ],
      user: {
        name: "Anonymous",
        email: null
      }
    });

  }]);
