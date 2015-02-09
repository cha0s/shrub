
{fork} = require "#{__dirname}/server/bootstrap"

module.exports = (grunt) ->

  # Fork so we can bootstrap a Shrub environment.
  if child = fork()
    grunt.registerTask 'bootstrap', ->

      done = @async()

      child.on 'close', (code) ->

        return done() if code is 0

        grunt.fail.fatal 'Child process failed', code

    # Forward all tasks.
    {tasks} = require 'grunt/lib/grunt/cli'
    grunt.registerTask tasks[0] ? 'default', ['bootstrap']
    grunt.registerTask(task, (->)) for task in tasks.slice 1

    return

  config = require 'config'
  pkgman = require 'pkgman'

  # } Load configuration.
  config.load()
  config.loadPackageSettings()

  class GruntConfiguration

    constructor: ->

      @_npmTasks = []
      @_taskConfig = {}
      @_tasks = {}

      @pkg = grunt.file.readJSON 'package.json'

    configureTask: (task, key, config_) ->

      (@_taskConfig[task] ?= {})[key] = config_

      return

    finish: ->

      # Initialize configuration.
      grunt.initConfig @_taskConfig

      # Load NPM tasks.
      npmTasksLoaded = {}
      for task in @_npmTasks
        continue if npmTasksLoaded[task]?
        npmTasksLoaded[task] = true
        grunt.loadNpmTasks task

      # Register custom tasks.
      grunt.registerTask task, actions for task, actions of @_tasks

      return

    taskConfiguration: (task, key) -> @_taskConfig[task]?[key]

    loadNpmTasks: (tasks) ->

      @_npmTasks.push task for task in tasks

      return

    registerTask: (task, subtasksOrFunction) ->

      if 'function' is typeof subtasksOrFunction
        @_tasks[task] = subtasksOrFunction
      else
        (@_tasks[task] ?= []).push subtasksOrFunction...

      return

  gruntConfig = new GruntConfiguration grunt

  gruntConfig.registerTask 'production', ['build']
  gruntConfig.registerTask 'default', ['buildOnce']

  built = false

  gruntConfig.registerTask 'buildOnce', ->
    return if built
    built = true

    grunt.task.run 'build'

  pkgman.invoke 'gruntConfig', gruntConfig, grunt
  pkgman.invoke 'gruntConfigAlter', gruntConfig, grunt

  gruntConfig.finish()
