# Grunt build process - Dynamic documentation

    {exec} = require 'child_process'
    fs = require 'fs'
    path = require 'path'
    {Transform} = require 'stream'

    _ = require 'lodash'
    {LineStream} = require 'byline'
    glob = require 'grunt/node_modules/glob'
    Promise = require 'bluebird'

Implement a Transform stream to accumulate hook invocations from a source file.

    class HookInvocations extends Transform

      constructor: ->
        super

        @list = []

      _transform: (chunk, encoding, done) ->
        line = chunk.toString('utf8')
        if matches = line.match /^\#\#\#\# Invoke hook `([^`]+)`/
          @list.push matches[1]

        done()

Implement a Transform stream to accumulate hook implementations from a source
file.

    class HookImplementations extends Transform

      constructor: ->
        super

        @list = []

      _transform: (chunk, encoding, done) ->
        line = chunk.toString('utf8')
        if matches = line.match /^\#\#\#\# Implements hook `([^`]+)`/
          @list.push matches[1]

        done()

Implement a Transform stream fo accumulate TODOs from a source file. Also
caches lines to be able to build context around each TODO item.

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

Gather all source files.

    _allSourceFiles = ->
      new Promise (resolve, reject) ->
        glob(
          '{{client,custom,packages,server}/**/*.litcoffee,*.litcoffee}'
          (error, files) ->
            return reject error if error?
            resolve files
        )

Generate an HTML ID from a hook name.

    _idFromHook = (hook) -> hook.replace(
      /[^0-9A-Za-z-]+/g, '-'
    ).replace(
      /\-+/g, '-'
    ).toLowerCase()

Get the source path from a filename. This removes the extension and any /index
portion from the end of the filename.

    _sourcePath = (filename) ->

        dirname = path.dirname filename
        if dirname is '.' then dirname = '' else dirname += '/'
        extname = path.extname filename
        filename = "#{dirname}#{path.basename filename, extname}"

        parts = filename.split '/'
        parts.pop() if parts[parts.length - 1] is 'index'
        return parts.join '/'

Collate a list of files by type (client or server).

    _collateFilesByType = (files) ->

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

Gather statistics for all files.

    fileStatsListPromise = _allSourceFiles().then (allFiles) ->

      allFilesPromises = for type, files of _collateFilesByType allFiles

        typePromises = for file in files

          do (type, file) -> new Promise (resolve, reject) ->

            fstream = fs.createReadStream file
            fstream.pipe lineStream = new LineStream keepEmptyLines: true

Pass all files through the Transform list to parse out relevant information.

            lineStream.pipe hookImplementations = new HookImplementations()
            lineStream.pipe hookInvocations = new HookInvocations()
            lineStream.pipe todos = new Todos()

            fstream.on 'error', reject

            fstream.on 'end', ->

Include all information from Transform streams in the statistics.

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

Massage the statistics to help rendering the hooks page.

    fileStatsListPromise.then((fileStatsList) ->

      hooksIndex = {}

      indexes = {}
      keys = ['implementations', 'invocations']

      for fileStats in fileStatsList

        for key in keys
          indexes[key] ?= {}

          for hook in fileStats[key]
            indexes[key][hook] ?= {}
            (indexes[key][hook][fileStats.file] ?= []).push fileStats.type

            hooksIndex[hook] = true

      for key in keys
        for hook, stats of indexes[key]
          for file of stats
            stats[file] = _.unique stats[file] ? []

      hooks = (hook for hook of hooksIndex).sort()

      hookFiles = {}
      for hook in hooks
        hookFiles[hook] = try
          fs.readFileSync "docs/hook/#{hook}.md", 'utf8'
        catch error
          ''

      O =
        hookFiles: hookFiles
        hooks: hooks

      O[key] = indexes[key] for key in keys

      return O

Render the hooks page.

    ).then((O) ->

      {hookFiles, hooks} = O

      keys = ['implementations', 'invocations']

      wordingFor =
        implementations: 'implements'
        invocations: 'invoke'

      render = fs.readFileSync 'docs/hooks.template.md', 'utf8'

      for hook in hooks

        render += "## #{hook}\n\n"
        render += hookFiles[hook] + '\n\n' if hookFiles[hook]

        for key in keys

          if O[key][hook]?

            count = Object.keys(O[key][hook]).length
            render += "### #{count} #{key}(s)\n\n"

            for file, types of O[key][hook]

              file = _sourcePath file

              types = types.map (type) -> "[#{type}](source/#{file}##{wordingFor[key]}-hook-#{_idFromHook hook})"

              render += "* #{file} (#{types.join ','})\n"

            render += '\n'

      new Promise (resolve, reject) ->
        fs.writeFile 'docs/hooks.md', render, (error) ->
          return reject error if error?
          resolve()

    ).done()

Render the TODOs page.

    fileStatsListPromise.then((fileStatsList) ->

      render = fs.readFileSync 'docs/todos.template.md', 'utf8'

      for fileStats in fileStatsList

Keep track of used IDs, it will be necessary to link to the correct location
hash in the case of multiple TODO items with the same wording.

        idMap = {}

        for todo in fileStats.todos

          render += '\n'

          id = ''
          for line, index in todo.lines
            render += '>'

If this is the line with the TODO, parse the ID from the TODO item text, and
render it as h2 (TODO are h6) to increase visibility.

            if index is Todos.context
              id = _idFromHook(line).slice 1, -1

              render += line.slice 4
            else
              render += " #{line}"
            render += '\n'

          render += '\n'

          filename = _sourcePath fileStats.file

Keep track of ID usage and modify the location hash for subsequent uses.

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

Add all the source files to a generated mkdocs.yml

    _allSourceFiles().then (files) ->

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

Add them under the 'Source code' path.

        yml += "- [source/#{file}, 'Source code', '#{file}']\n"

      fs.writeFileSync 'mkdocs.yml', yml

      return

Render the packages page.

    fileStatsListPromise.then((fileStatsList) ->

Sort by package name first.

      newList = []

      for fileStats in fileStatsList

        parts = fileStats.file.split '/'
        continue unless ~['custom', 'packages'].indexOf parts[0]

        sourcePath = _sourcePath fileStats.file

        parts = sourcePath.split '/'
        parts.pop() if parts[parts.length - 1] is 'client'
        pkg = parts.join '/'
        fileStats.pkg = pkg.split('/').slice(1).join '/'

        newList.push fileStats

      newList.sort (l, r) ->
        return -1 if l.type is 'client' and r.type is 'server'
        return 1 if l.type is 'server' and r.type is 'client'
        if l.pkg < r.pkg then -1 else if l.pkg > r.pkg then 1 else 0

    ).then((fileStatsList) ->

      render = fs.readFileSync 'docs/packages.template.md', 'utf8'
      render += '\n'

      type = null

      for fileStats in fileStatsList

        if fileStats.type isnt type
          type = fileStats.type

          render += if type is 'client'
            '## Client-side'
          else
            '## Server-side'

          render += '\n\n'

        isSubpackage = fileStats.pkg.split('/').length isnt 1

Link to the package.

        sourcePath = _sourcePath fileStats.file

        if isSubpackage
          render += '> '
          parts = fileStats.pkg.split '/'
          parentPkg = parts.shift()
          subPkg = parts.join '/'
          render += "## [<small>#{parentPkg}/</small>#{subPkg}](source/#{sourcePath})"
        else
          render += "## [#{fileStats.pkg}](source/#{sourcePath})"

Naively parse out the file description. It must be wrapped in asterisks, i.e.
italicized in markdown.

###### TODO: This 'chunk' parsing should be done with a Transform like the others.

        data = fs.readFileSync fileStats.file, 'utf8'
        chunks = data.split '\n\n'

        title = chunks[0]
        if 35 is title.charCodeAt 0
          render += " &mdash; #{title.substr 2}"

        render += '\n\n'

        description = chunks[1]
        if 42 is description.charCodeAt 0 and 42 is description.charCodeAt description.length - 1
          render += '> ' if isSubpackage
          render += "#{description}\n\n"

        if fileStats.implementations.length > 0
          render += '> ' if isSubpackage
          render += '!!! note "Implements hooks"\n    '
          render += fileStats.implementations.map((hook) ->
            "[#{hook}](source/#{sourcePath}#implements-hook-#{hook.toLowerCase()})"
          ).join ', '
          render += '\n\n'

        if fileStats.invocations.length > 0
          render += '> ' if isSubpackage
          render += '!!! note "Invokes hooks"\n    '
          render += fileStats.invocations.map((hook) ->
            "[#{hook}](source/#{sourcePath}#invoke-hook-#{hook.toLowerCase()})"
          ).join ', '
          render += '\n\n'

###### TODO: We should do some preprocessing hre with a transform, namely linking the hook headers to their respective documentation.

      fs.writeFileSync 'docs/packages.md', render

    )
