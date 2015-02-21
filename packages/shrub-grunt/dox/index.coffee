
exports.pkgmanRegister = (registrar) ->

  # ## Implements hook `gruntConfig`
  registrar.registerHook 'gruntConfig', (gruntConfig, grunt) ->

    {fork} = require 'child_process'

    gruntConfig.registerTask 'dox:prepareDirectory', ->
      grunt.file.mkdir 'gh-pages'

    gruntConfig.registerTask 'dox:dynamic', ->
      done = @async()

      fork("#{__dirname}/dynamic.litcoffee").on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Dynamic documentation generation failed', code

    gruntConfig.registerTask 'dox', [
       'dox:prepareDirectory'
       'dox:dynamic'
    ]
