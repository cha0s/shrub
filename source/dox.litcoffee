
# Documentation generation

*Generate the dynamic portions of Shrub's documentation.*

    fs = require 'fs'
    path = require 'path'
    {Transform} = require 'stream'

    _ = require 'lodash'
    {LineStream} = require 'byline'
    glob = require 'grunt/node_modules/glob'
    Promise = require 'bluebird'

    class HookInvocations extends Transform

      constructor: ->
        super

        @list = []

      _transform: (chunk, encoding, done) ->
        line = chunk.toString('utf8')
        if matches = line.match /^\#\#\#\# Invoke hook `([^`]+)`/
          @list.push matches[1]

        done()

    class HookImplementations extends Transform

      constructor: ->
        super

        @list = []

      _transform: (chunk, encoding, done) ->
        line = chunk.toString('utf8')
        if matches = line.match /^\#\#\#\# Implements hook `([^`]+)`/
          @list.push matches[1]

        done()

    class Todos extends Transform

      @context = 4

      constructor: ->
        super

        @lines = []
        @todos = []

      _transform: (chunk, encoding, done) ->
        @lines.push line = chunk.toString('utf8')
        if matches = line.match /^\#\#\#\#\#\# TODO/
          @todos.push @lines.length - 1

        done()

      withContext: ->

        for todo in @todos

          start = Math.max 0, todo - Todos.context
          end = Math.min @lines.length - 1, todo + Todos.context

          index: todo
          lines: @lines.slice start, end

    _getFiles = ->
      new Promise (resolve, reject) ->
        glob(
          '{{client,custom,packages,server}/**/*.litcoffee,*.litcoffee}'
          (error, files) ->
            return reject error if error?
            resolve files
        )

    _getPackageFiles = ->  _getFiles().then (files) ->
      new Promise (resolve, reject) ->
        glob(
          '{custom,packages}/**/*.litcoffee'
          (error, files) ->
            return reject error if error?
            resolve files
        )

    _hookToId = (hook) -> hook.replace(
      /[^0-9A-Za-z-]+/g, '-'
    ).toLowerCase()

    _removeExtension = (filename) ->

        dirname = path.dirname filename
        if dirname is '.' then dirname = '' else dirname += '/'
        extname = path.extname filename
        filename = "#{dirname}#{path.basename filename, extname}"

        parts = filename.split '/'
        parts.pop() if parts[parts.length - 1] is 'index'
        return parts.join '/'

    _sortFilesByType = (files) ->

      client = []
      server = []

      for file in files
        parts = file.split '/'

        if parts[0] is 'client'
          client.push file
        else if parts[0] is 'custom' and parts[2] is 'client'
          client.push file
        else if parts[0] is 'packages' and parts[2] is 'client'
          client.push file
        else
          server.push file

      client: client, server: server

    fileStatsListPromise = _getFiles().then (allFiles) ->

      allFilesPromises = for type, files of _sortFilesByType allFiles

        typePromises = for file in files

          do (type, file) -> new Promise (resolve, reject) ->

            fstream = fs.createReadStream file
            fstream.pipe lineStream = new LineStream keepEmptyLines: true

            lineStream.pipe hookImplementations = new HookImplementations()
            lineStream.pipe hookInvocations = new HookInvocations()
            lineStream.pipe todos = new Todos()

            fstream.on 'error', reject

            fstream.on 'end', ->
              resolve(
                type: type
                file: file
                implementations: hookImplementations.list
                invocations: hookInvocations.list
                todos: todos.withContext()
              )

        Promise.all typePromises

      Promise.all(allFilesPromises).then (fileStatsLists) ->
        _.flatten fileStatsLists

    fileStatsListPromise.then((fileStatsList) ->

      hooksIndex = {}
      implementations = {}
      invocations = {}

      for fileStats in fileStatsList

        for implementation in fileStats.implementations
          impl = implementations[implementation] ?= {}
          (impl[fileStats.file] ?= []).push fileStats.type

          hooksIndex[implementation] = true

        for invocation in fileStats.invocations
          invo = invocations[invocation] ?= {}
          (invo[fileStats.file] ?= []).push fileStats.type

          hooksIndex[invocation] = true

      for hook, stats of implementations
        for file of stats
          stats[file] = _.unique stats[file] ? []

      for hook, stats of invocations
        for file of stats
          stats[file] = _.unique stats[file] ? []

      hooks = (hook for hook of hooksIndex).sort()

      hookFiles = {}
      for hook in hooks
        hookFiles[hook] = try
          fs.readFileSync "docs/hook/#{hook}.md", 'utf8'
        catch error
          ''

      hookFiles: hookFiles
      hooks: hooks
      implementations: implementations
      invocations: invocations

    ).then(({hookFiles, hooks, implementations, invocations}) ->

      render = fs.readFileSync 'docs/hooks.template.md', 'utf8'

      for hook in hooks

        render += "## #{hook}\n\n"
        render += hookFiles[hook] + '\n\n' if hookFiles[hook]

        if implementations[hook]?

          implementationCount = Object.keys(implementations[hook]).length
          render += "### #{implementationCount} implementation(s)\n\n"

          for file, types of implementations[hook]

            file = _removeExtension file

            types = types.map (type) -> "[#{type}](source/#{file}#implements-hook-#{hook.toLowerCase()})"

            render += "* #{file} (#{types.join ','})\n"

          render += '\n'

        if invocations[hook]?

          invocationCount = Object.keys(invocations[hook]).length
          render += "### #{invocationCount} invocation(s)\n\n"

          for file, types of invocations[hook]

            file = _removeExtension file

            types = types.map (type) -> "[#{type}](source/#{file}#invoke-hook-#{hook.toLowerCase()})"

            render += "* #{file} (#{types.join ','})\n"

          render += '\n'

      new Promise (resolve, reject) ->
        fs.writeFile 'docs/hooks.md', render, (error) ->
          return reject error if error?
          resolve()

    ).done()

    fileStatsListPromise.then((fileStatsList) ->

      render = fs.readFileSync 'docs/todos.template.md', 'utf8'

      for fileStats in fileStatsList

        idMap = {}

        for todo in fileStats.todos

          render += '\n'

          id = ''
          for line, index in todo.lines
            render += '>'

            if index is Todos.context
              id = _hookToId(line).slice 1, -1

              render += line.slice 4
            else
              render += " #{line}"
            render += '\n'

          render += '\n'

          filename = _removeExtension fileStats.file

          if idMap[id]?
            idMap[id] += 1
            id += "_#{idMap[id]}"
          else
            idMap[id] = 0

          render += "###### the above found in [#{fileStats.file}:#{todo.index}](source/#{filename}##{id})\n"

      new Promise (resolve, reject) ->
        fs.writeFile 'docs/todos.md', render, (error) ->
          return reject error if error?
          resolve()

    ).done()

    _getFiles().then (files) ->

      yml = fs.readFileSync 'docs/mkdocs.template.yml', 'utf8'

      for file in files
        parts = file.split '/'

        for i in [0...parts.length]
          try
            fs.mkdirSync "docs/source/#{parts.slice(0, i).join '/'}"
          catch error

        fs.createReadStream(file).pipe(
          fs.createWriteStream("docs/source/#{file}")
        )

        yml += "- [source/#{file}, 'Source code', '#{file}']\n"

      fs.writeFileSync 'mkdocs.yml', yml

      return

    _getPackageFiles().then (allFiles) ->

      render = fs.readFileSync 'docs/packages.template.md', 'utf8'
      render += '\n'

      for type, files of _sortFilesByType allFiles

        render += if type is 'client'
          '## Client-side'
        else
          '## Server-side'

        render += '\n\n'

        for file in files

          data = fs.readFileSync file, 'utf8'

          chunks = data.split '\n\n'

          path = _removeExtension file
          pkg = path.split('/').pop()

          render += "### [#{pkg}](source/#{path})\n\n"

          description = chunks[1]

Description is wrapped in asterisks, i.e. italicized in markdown.

          if 42 is description.charCodeAt 0 and 42 is description.charCodeAt chunks.length - 1
            render += "#{description}\n\n"


      fs.writeFileSync 'docs/packages.md', render


