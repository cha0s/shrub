# # Grunt build process - Documentation
#
# *Build the documentation in `gh-pages`.*
{fork, spawn} = require 'child_process'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubGruntConfig`.
  registrar.registerHook 'shrubGruntConfig', (gruntConfig, grunt) ->

    gruntConfig.registerTask 'dox:prepareDirectory', ->
      grunt.file.mkdir 'gh-pages'

    gruntConfig.registerTask 'dox:dynamic', ->
      done = @async()

      fork("#{__dirname}/dynamic.coffee").on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Dynamic documentation generation failed', code

    gruntConfig.registerTask 'dox:mkdocs', ->
      done = @async()

      spawn('mkdocs', ['build']).on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Running `mkdocs build` failed', code

    gruntConfig.registerTask 'dox', [
       'dox:prepareDirectory'
       'dox:dynamic'
       'dox:mkdocs'
    ]