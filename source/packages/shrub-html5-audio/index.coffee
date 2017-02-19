# HTML5 audio

```coffeescript
fs = require 'fs'
path = require 'path'
pkgman = require 'pkgman'

audioFiles = null

gatherAudioFiles = ->

  unless audioFiles?
    audioFiles = {}
    for pkg, globs of pkgman.invoke 'shrubHtml5Audio'
      audioFiles[pkg] = globs ? ['audio']

  return audioFiles

exports.pkgmanRegister = (registrar) ->

  registrar.registerHook 'shrubConfigClient', ->

    simpleGlob = require 'simple-glob'

    qualifiedFiles = {}
    for pkg, globs of gatherAudioFiles()
      for glob in globs
        directory = "#{path.dirname require.resolve pkg}/#{glob}"
        for filename in simpleGlob "#{directory}/**/*"
          stats = fs.statSync filename
          continue if stats.isDirectory()
          filename = filename.slice directory.length
          filedir = path.dirname filename
          filedir += '/' if filedir isnt '/'
          fileext = path.extname filename
          filebase = path.basename filename, fileext
          fileext = fileext.slice 1
          filename = "#{pkg}/#{filedir.slice 1}#{filebase}"
          (qualifiedFiles[filename] ?= []).push fileext

    files: qualifiedFiles

  registrar.registerHook 'shrubHtml5Audio', ->

  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    tasks = []

    for pkg, globs of gatherAudioFiles()
      for glob in globs

        task = "shrub-html5-audio-#{pkg}"
        tasks.push task

        gruntConfig.copyAppFiles(
          "#{path.dirname require.resolve pkg}/#{glob}"
          task
          "app/audio/#{pkg}"
        )

    tasks = tasks.map (task) -> "newer:copy:#{task}"
    gruntConfig.registerTask 'build:shrub-html5-audio', tasks
    gruntConfig.registerTask 'build', ['build:shrub-html5-audio']

    return
```
