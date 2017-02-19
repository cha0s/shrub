# # Grunt build process - Dynamic documentation
{exec} = require 'child_process'
fs = require 'fs'
path = require 'path'
{Transform} = require 'stream'

_ = require 'lodash'
{LineStream} = require 'byline'
glob = require 'grunt/node_modules/glob'
Promise = require 'bluebird'

# Implement a Transform stream to accumulate hook invocations from a source
# file.
class HookInvocations extends Transform

  constructor: ->
    super

    @list = []

  _transform: (chunk, encoding, done) ->
    line = chunk.toString('utf8')
    if matches = line.match /^\s*# #### Invoke hook `([^`]+)`/
      @list.push matches[1]

    done()

# Implement a Transform stream to accumulate hook implementations from a
# source file.
class HookImplementations extends Transform

  constructor: ->
    super

    @list = []

  _transform: (chunk, encoding, done) ->
    line = chunk.toString('utf8')
    if matches = line.match /^\s*# #### Implements hook `([^`]+)`/
      @list.push matches[1]

    done()

# Implement a Transform stream to accumulate TODOs from a source file. Also
# caches lines to be able to build context around each TODO item.
class Todos extends Transform

  @context = 4

  constructor: ->
    super

    @lines = []
    @todos = []

  _transform: (chunk, encoding, done) ->
    @lines.push line = chunk.toString('utf8')
    if matches = line.match /^\s*# ###### TODO/
      @todos.push @lines.length - 1

    done()

  withContext: ->

    for todo in @todos

      start = Math.max 0, todo - Todos.context
      end = Math.min @lines.length - 1, todo + Todos.context

      index: todo
      lines: @lines.slice start, end

# Implement a Transform stream to parse title and description for a file.
class TitleAndDescription extends Transform

  constructor: ->
    super

    @hasFinishedParsing = false

    @title = ''
    @description = ''

  _transform: (chunk, encoding, done) ->

    return done() if @hasFinishedParsing

    line = chunk.toString('utf8').trim()
    return done() if line.length is 0

    if 35 is line.charCodeAt(0)

      if 35 is line.charCodeAt(2)
        @title = line.substr 4

      else if 42 is line.charCodeAt(2)
        @description = line.substr 2

      else if @description?
        @description += ' ' + line.substr 2

      if 42 is @description.charCodeAt @description.length - 1
        @hasFinishedParsing = true

    else

      @hasFinishedParsing = true

    return done()

# Implement a transform stream to convert a .coffee file to .litcoffee
class LitcoffeeConversion extends Transform

  constructor: (@filename) ->
    super

    @highlight = if @filename.match /\.(?:lit)?coffee$/
      'coffeescript'
    else if @filename.match /\.js$/
      'javascript'
    else
      'no-highlight'

    @hanging = []
    @hasWrittenCode = false
    @commenting = false

    @on 'finish', => @unshift "```\n" if @hasWrittenCode and not @commenting

  _transform: (chunk, encoding, done) ->

    line = chunk.toString 'utf8'

    # Comment.
    if '#'.charCodeAt(0) is line.trim().charCodeAt(0)

      @push "```\n\n" if @hasWrittenCode and not @commenting

      comment = line.trim().substr 2

      matches = comment.match /^#### (I(?:nvoke|mplements)) hook `([^`]+)`/
      if matches

        parts = path.dirname(@filename).split('/')
        parts.push '' if 'index.coffee' isnt path.basename @filename
        backpath = parts.map(-> '..').join '/'

        @push "#### #{
          matches[1]
        } hook [`#{
          matches[2]
        }`](#{
          backpath
        }/hooks##{
          matches[2].toLowerCase()
        })\n"

      else

        @push "#{comment}\n"

      @commenting = true

    else

      @hanging = [] if @commenting
      @push "\n```#{@highlight}\n" if @commenting or not @hasWrittenCode

      if line.length is 0
        @hanging.push '' unless @commenting
      else
        @push "\n" for blank in @hanging
        @hanging = []
        @push "#{line}\n"

      @commenting = false
      @hasWrittenCode = true

    done()

# Gather all source files.
_allSourceFiles = ->
  new Promise (resolve, reject) ->
    glob(
      '{{client,custom,packages,server}/**/*.{coffee,litcoffee},*.{coffee,litcoffee},config/default.settings.yml}'
      (error, files) ->
        return reject error if error?
        resolve files
    )

# Generate an HTML ID from a string.
_idFromString = (string) -> string.replace(
  /[/'']/g, ''
).replace(
  /\[(.*)\]\(.*\)/g, '$1'
).replace(
  /[^0-9A-Za-z-]+/g, '-'
).replace(
  /\-+/g, '-'
).toLowerCase()

# Get the source path from a filename. This removes the extension and any
# /index portion from the end of the filename.
_sourcePath = (filename) ->

    dirname = path.dirname filename
    if dirname is '.' then dirname = '' else dirname += '/'
    extname = path.extname filename
    filename = "#{dirname}#{path.basename filename, extname}"

    parts = filename.split '/'
    parts.pop() if parts[parts.length - 1] is 'index'
    return parts.join '/'

# Collate a list of files by type (client or server).
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

# Add all the source files to a generated mkdocs.yml
generatedFilesPromise = _allSourceFiles().then (files) ->

  promises = for file in files
    parts = file.split '/'

    for i in [0...parts.length]
      try
        fs.mkdirSync "docs/source/#{parts.slice(0, i).join '/'}"
      catch error

    fstream = fs.createReadStream file
    fstream.pipe lineStream = new LineStream keepEmptyLines: true

    # Convert to litcoffee.
    lineStream.pipe litcoffeeConversion = new LitcoffeeConversion file
    writeStream = fs.createWriteStream "docs/source/#{file}"
    litcoffeeConversion.pipe writeStream

    new Promise (resolve) -> do (file) ->

      writeStream.on 'close', -> resolve file

  Promise.all promises

# Gather statistics for all files.
fileStatsListPromise = generatedFilesPromise.then (allFiles) ->

  allFilesPromises = for type, files of _collateFilesByType allFiles

    typePromises = for file in files

      do (type, file) -> new Promise (resolve, reject) ->

        fstream = fs.createReadStream file
        fstream.pipe lineStream = new LineStream keepEmptyLines: true

        # Pass all files through the Transform list to parse out relevant
        # information.
        lineStream.pipe hookImplementations = new HookImplementations()
        lineStream.pipe hookInvocations = new HookInvocations()
        lineStream.pipe todos = new Todos()
        lineStream.pipe titleAndDescription = new TitleAndDescription()

        fstream.on 'error', reject

        fstream.on 'end', ->

          # Include all information from Transform streams in the statistics.
          resolve(
            type: type
            file: file
            implementations: hookImplementations.list
            invocations: hookInvocations.list
            todos: todos.withContext()
            title: titleAndDescription.title
            description: titleAndDescription.description
          )

    Promise.all typePromises

  Promise.all(allFilesPromises).then (fileStatsLists) ->
    _.flatten fileStatsLists

# Massage the statistics to help rendering the hooks page.
fileStatsListPromise.then((fileStatsList) ->

  hooksIndex = {}

  indexes = {}
  keys = ['implementations', 'invocations']

  for fileStats in fileStatsList

    parts = fileStats.file.split '/'
    for remove in ['client', 'packages']
      if ~(index = parts.indexOf remove)
        parts.splice index, 1
    mergeFile = parts.join '/'

    for key in keys
      indexes[key] ?= {}

      for hook in fileStats[key]
        indexes[key][hook] ?= {}

        indexes[key][hook][mergeFile] ?= fullName: fileStats.file
        (indexes[key][hook][mergeFile].types ?= []).push fileStats.type

        hooksIndex[hook] = true

  for key in keys
    for hook, stats of indexes[key]
      for file of stats
        stats[file].types = _.sortedUniq stats[file].types.sort() ? []

  hooks = (hook for hook of hooksIndex).sort()

  hookFiles = {}
  for hook in hooks
    hookFiles[hook] = try
      fs.readFileSync "docs/hook/#{hook}.md", 'utf8'
    catch error
      console.error "Missing hook template for #{hook}"
      ''

  O =
    hookFiles: hookFiles
    hooks: hooks

  O[key] = indexes[key] for key in keys

  return O

# Render the hooks page.
).then((O) ->

  {hookFiles, hooks} = O

  keys = ['implementation', 'invocation']

  wordingFor =
    implementation: 'implements'
    invocation: 'invoke'

  render = fs.readFileSync 'docs/hooks.template.md', 'utf8'

  for hook in hooks

    render += "## #{hook}\n\n"
    render += hookFiles[hook] + '\n\n' if hookFiles[hook]

    for key in keys
      pluralKey = "#{key}s"

      if O[pluralKey][hook]?

        count = 0
        for file, {types} of O[pluralKey][hook]
          count += types.length

        render += '<div class="admonition note">'
        render += "<p class=\"admonition-title\">#{count} #{key}"
        render += 's' if count > 1
        render += '</p>\n'
        render += '  <table>\n'

        stripe = 0
        instances = for file, {fullName, types} of O[pluralKey][hook]

          # Remove client path part, only added when necessary.
          parts = fullName.split '/'
          for remove in ['client']
            if ~(index = parts.indexOf remove)
              parts.splice index, 1
          fullName = parts.join '/'

          parts = file.split '/'
          for remove in ['client']
            if ~(index = parts.indexOf remove)
              parts.splice index, 1
          file = parts.join '/'

          addClientToFullPath = (isClient, path) ->

            return path unless isClient
            parts = path.split '/'
            return path if parts[0] isnt 'packages'
            parts.splice 2, 0, 'client'
            parts.join '/'

          do (fullName) -> types = types.map (type) ->
            "    <tr class=\"#{
              if stripe++ % 2 then 'odd' else 'even'
            }\"><td><a href=\"../source/#{
              addClientToFullPath type is 'client', _sourcePath fullName
            }\">#{
              _sourcePath file
            } (#{
              type
            })</a></td><td align=\"right\"><a href=\"../source/#{
              addClientToFullPath type is 'client', _sourcePath fullName
            }##{
              wordingFor[key]
            }-hook-#{
              _idFromString hook
            }\">#{
              key
            }</a></td></tr>"
          types.join ''

        render += instances.join ''

        render += '  </table>\n'
        render += '</div>'
        render += '\n\n'

  new Promise (resolve, reject) ->
    fs.writeFile 'docs/hooks.md', render, (error) ->
      return reject error if error?
      resolve()

).done()

# Render the TODOs page.
fileStatsListPromise.then((fileStatsList) ->

  render = fs.readFileSync 'docs/todos.template.md', 'utf8'

  for fileStats in fileStatsList

    # Keep track of used IDs, it will be necessary to link to the correct
    # location hash in the case of multiple TODO items with the same wording.
    idMap = {}

    for todo in fileStats.todos

      filename = _sourcePath fileStats.file

      highlight = if fileStats.file.match /\.(?:lit)?coffee$/
         'coffeescript'
      else if fileStats.file.match /\.js$/
        'javascript'
      else
        'no-highlight'

      render += "\n---\n\n```#{highlight}\n"

      id = ''
      for line, index in todo.lines

        # If this is the line with the TODO, parse the ID from the TODO item
        # text, and render it as h2 (TODO are h6) to increase visibility.
        if index is Todos.context
          id = _idFromString(line).slice 1, -1

          render += "```\n\n#{line.trim().slice 6}\n\n```#{highlight}"
        else
          render += line
        render += '\n'

      render += '```\n\n'

      # Keep track of ID usage and modify the location hash for subsequent
      # uses.
      if idMap[id]?
        idMap[id] += 1
        id += "_#{idMap[id]}"
      else
        idMap[id] = 0

      render += "[the above found in #{
        fileStats.file
      }:#{
        todo.index
      }](source/#{
        filename
      }##{
        id
      })\n\n"

  new Promise (resolve, reject) ->
    fs.writeFile 'docs/todos.md', render, (error) ->
      return reject error if error?
      resolve()

).done()

_allSourceFiles().then (files) ->

  yml = fs.readFileSync 'docs/mkdocs.template.yml', 'utf8'

  renderHierarchy = (output, hierarchy) ->

    renderHierarchyInternal = (output, hierarchy, indent) ->

      if _.isString hierarchy

        output[output.length - 1] += " '#{hierarchy}'"

      else

        for k, v of hierarchy

          output.push "#{indent}- #{k}:"
          renderHierarchyInternal output, v, "#{indent}    "

    renderHierarchyInternal output, hierarchy, ''

  hierarchy = Source: {}
  for file in files
    walk = hierarchy.Source
    parts = file.split '/'
    for part, i in parts
      if i is parts.length - 1
        walk[part] = "source/#{file}"
      else
        walk[part] ?= {}
        walk = walk[part]

  output = []
  renderHierarchy output, hierarchy
  fs.writeFileSync 'mkdocs.yml', yml + output.join "\n"

# Render the packages page.
fileStatsListPromise.then((fileStatsList) ->

  # Sort by package name first.
  newList = []

  for fileStats in fileStatsList

    parts = fileStats.file.split '/'
    continue unless ~['custom', 'packages'].indexOf parts[0]

    sourcePath = _sourcePath fileStats.file

    parts = sourcePath.split '/'
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

    pkgParts = fileStats.pkg.split '/'
    isSubpackage = pkgParts.length isnt 1 and pkgParts.pop() isnt 'client'

    # Link to the package.
    sourcePath = _sourcePath fileStats.file

    if isSubpackage
      render += '> '
      parts = fileStats.pkg.split '/'
      parentPkg = parts.shift()
      subPkg = parts.join '/'
      render += "## [<small>#{parentPkg}/</small>#{subPkg}](source/#{sourcePath})"
    else
      render += "## [#{fileStats.pkg}](source/#{sourcePath})"

    if fileStats.title?
      render += '\n\n'
      render += '> ' if isSubpackage
      render += "<span class=\"package-title\">#{fileStats.title}</span>"

    render += '\n\n'

    if fileStats.description?
      render += '> ' if isSubpackage
      render += "#{fileStats.description}\n\n"

    if fileStats.implementations.length > 0
      render += '> ' if isSubpackage
      render += '<div class="admonition note">'
      render += '<p class="admonition-title">Implements hooks</p>'
      render += '  <table>\n'
      render += fileStats.implementations.map((hook, index) ->
        "    <tr class=\"#{if index % 2 then 'odd' else 'even'}\"><td><a href=\"../hooks/##{_idFromString hook}\">#{hook}</a></td><td align=\"right\"><a href=\"../source/#{sourcePath}#implements-hook-#{hook.toLowerCase()}\">implementation</a></td></tr>\n"
      ).join ''
      render += '  </table>\n'
      render += '</div>'
      render += '\n\n'

    if fileStats.invocations.length > 0
      render += '> ' if isSubpackage
      render += '<div class="admonition note">'
      render += '<p class="admonition-title">Invokes hooks</p>'
      render += '  <table>\n'
      render += fileStats.invocations.map((hook, index) ->
        "    <tr class=\"#{if index % 2 then 'odd' else 'even'}\"><td><a href=\"../hooks/##{_idFromString hook}\">#{hook}</a></td><td align=\"right\"><a href=\"../source/#{sourcePath}#invoke-hook-#{hook.toLowerCase()}\">invocation</a></td></tr>\n"
      ).join ''
      render += '  </table>\n'
      render += '</div>'
      render += '\n\n'

  fs.writeFileSync 'docs/packages.md', render

)