# Grunt build process - Run tests
```coffeescript
exports.pkgmanRegister = (registrar) ->
```
#### Implements hook `shrubGruntConfig`.
```coffeescript
  registrar.registerHook 'shrubGruntConfig', (gruntConfig, grunt) ->

    {fork, spawn} = require 'child_process'

    gruntConfig.configureTask(
      'karma', 'testsUnit'

      options:

        basePath: "#{__dirname}/../../.."

        files: [
          'app/lib/angular/angular.js'
          'app/lib/angular/angular-*.js'
          'test/lib/angular/angular-mocks.js'
          'app/lib/shrub/shrub.js'
          'test/unit/config.js'
          'test/unit/tests.js'
        ]

        exclude: [
          'app/lib/angular/angular-loader.js'
          'app/lib/angular/*.min.js'
          'app/lib/angular/angular-scenario.js'
        ]

        frameworks: [
          'jasmine'
        ]

        browsers: [
          'Chrome'
        ]

        plugins: [
          'karma-junit-reporter'
          'karma-chrome-launcher'
          'karma-firefox-launcher'
          'karma-jasmine'
        ]

        singleRun: true

        junitReporter:

          outputFile: 'test_out/unit.xml'
          suite: 'unit'

    )

    gruntConfig.configureTask(
      'protractor', 'testsE2e'

      options:
        configFile: 'config/protractor.conf.js'
        keepAlive: false
        noColor: true

    )

    e2eServerChild = null

    gruntConfig.registerTask 'tests:e2eServerUp', ->

      done = @async()

      openServerPort().then (port) ->
```
Pass arguments to the child process.
```coffeescript
        args = process.argv.slice 2
```
Pass the environment to the child process.
```coffeescript
        options = env: process.env
        options.env['E2E'] = 'true'
        options.env['packageSettings:shrub-http:port'] = port
```
Fork it.
```coffeescript
        e2eServerChild = fork(
          "#{__dirname}/../../../node_modules/coffee-script/bin/coffee"
          ["#{__dirname}/../../../server.coffee"]
          options
        )
```
Inject the port configuration.
```coffeescript
        protractorConfig = gruntConfig.taskConfiguration(
          'protractor', 'testsE2e'
        )
        baseUrl = "http://localhost:#{port}/"
        protractorConfig.options.args = baseUrl: baseUrl
```
Wait for the server to come up.
```coffeescript
        grunt.log.write 'Waiting for E2E server to come up...'
        require('tcp-port-used').waitUntilUsed(port, 400, 30000).then(

          ->
            grunt.task.run 'protractor:testsE2e'
            done()

          (error) -> grunt.fail.fatal 'E2E server never came up after 30 seconds!'
        )

    openServerPort = ->
      new (require 'bluebird') (resolve, reject) ->
        server = require('net').createServer()

        server.listen 0, ->
          {port} = server.address()
          server.close -> resolve port

        server.on 'error', reject

    gruntConfig.registerTask 'tests:e2eServerDown', ->
      e2eServerChild.on 'close', @async()
      e2eServerChild.kill()

    gruntConfig.registerTask 'tests:e2e', [
      'buildOnce'
      'tests:e2eServerUp'
      'tests:e2eServerDown'
    ]

    gruntConfig.registerTask 'tests:unitConfig', ->
      done = @async()

      req = new require('http').IncomingMessage
      req.grunt = true

      require('shrub-config').renderPackageConfig(req).then (code) ->

        grunt.file.write 'test/unit/config.js', code

        done()

    gruntConfig.registerTask 'tests:unit', [
      'buildOnce'
      'tests:unitConfig'
      'karma:testsUnit'
    ]

    gruntConfig.registerTask 'tests:jasmineFunction', ->

      done = @async()
```
Spawn node Jasmine.
```coffeescript
      spawn(
        'node'
        [
          "#{__dirname}/../../../node_modules/jasmine-node/lib/jasmine-node/cli.js"
          '--coffee', 'client', 'packages', 'custom'
        ]
        stdio: 'inherit'
      ).on 'close', (code) ->
        return done() if code is 0
        grunt.fail.fatal 'Jasmine tests not passing!'

    gruntConfig.registerTask 'tests:jasmine', [
      'buildOnce'
      'tests:jasmineFunction'
    ]

    gruntConfig.registerTask 'tests', [
       'tests:jasmine'
       'tests:unit'
       'tests:e2e'
    ]

    gruntConfig.loadNpmTasks [
      'grunt-karma'
      'grunt-protractor-runner'
    ]
```
