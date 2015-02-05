
# # Generate documentation
#
# Various parts of the documentation are generated dynamically. This file
# parses the source files and generates the respective documentation files.

child_process = require 'child_process'
path = require 'path'
fs = require 'fs'

glob = require 'groc/node_modules/glob'

# Load the groc configuration and read all sources.
grocConfig = JSON.parse fs.readFileSync '.groc.json', encoding: 'utf8'

files = {}
for globExpression in grocConfig.glob
	files[file] = true for file in glob.sync globExpression
for globExpression in grocConfig.except
	delete files[file] for file in glob.sync globExpression

sources = {}
for filename of files

	raw = fs.readFileSync filename, encoding: 'utf8'
	lines = raw.split('\n').map (line) -> line.trim()

	commentLines = lines.map (line) ->
		if line.match /^\#\s.+/ then line else ''

	sources[filename] =
		raw: raw
		lines: lines
		commentLines: commentLines

# } Get the type and name of this package (if any).
packageTypeAndName = (filename, onlyParent) ->

	return unless (matches = filename.match /([^/]+)\/([^/]+)\/([^/]+)/)?
	return if -1 is ['custom', 'packages'].indexOf matches[1]

	parts = filename.split '/'
	parts = parts.slice 1

	type = if matches[3] is 'client'

		parts.splice 1, 1

		'client'

	else

		'server'

	lastPart = parts[parts.length - 1]
	parts[parts.length - 1] = "#{
		path.basename lastPart, path.extname lastPart
	}"

	# } Chop off trailing 'index'
	parts.pop() if parts[parts.length - 1] is 'index'

	# } Only return parent package?
	parts = parts.slice 0, 1 if onlyParent

	type: type, name: parts.join '/'

packageInformation = {}
packageLookup = {}
for filename, {commentLines} of sources

	continue unless (typeAndName = packageTypeAndName filename, true)?
	{type, name} = typeAndName

	packageInformation[type] ?= {}
	packageLookup[filename] = name: name, type: type

	# } Only do this once for each package.
	continue if packageInformation[type][name]?
	continue unless filename.match /\/index\.(coffee|js)$/

	packageInformation[type][name] = filename: filename

# Generate hook documentation.
generateHookDocumentation = do ->

	markdown = """

# Hook overview

Shrub implements message passing between packages through a hook system. Hooks
may be invoked with [pkgman.invoke()](/client/modules/pkgman.html), and are
implemented in packages by exporting `pkgmanRegister`.

For instance, if we are implementing a package and want to implement the
`httpListening` hook, our code would look like:

	exports.pkgmanRegister = (registrar) ->

		registrar.registerHook 'httpListening', ->

			# Your code goes here...

The list below was dynamically generated from the source code. There is a
description and a list of implementing packages for each hook.

"""

	packagesImplementingHook = (hookName) ->

		implementsPattern = new RegExp "^\#\\s(\#\# )?Implements hook `#{
			hookName
		}`"

		packages = {}

		for filename, {commentLines} of sources
			continue unless (typeAndName = packageTypeAndName filename, false)?
			typeAndName.filename = filename

			some = commentLines.some (line) -> line.match implementsPattern
			if some

				package_ = packages[typeAndName.name] ?= typeAndName
				(package_.typesAndFilenames ?= []).push
					type: typeAndName.type, filename: filename

		package_ for _, package_ of packages

	hookInformation = {}
	for filename, {commentLines} of sources

		for commentLine, index in commentLines

			# } Find the comment with the hook invocation, and retrieve the
			# } hook name.
			if matches = commentLine.match /^\#\sInvoke hook `([^`]+)`/

				# } Look ahead until we hit an empty line; all following lines
				# } until then are the hook description.
				description = ''
				hookName = matches[1]
				lookaheadIndex = index + 1
				while lookaheadLine = commentLines[lookaheadIndex]
					matches = lookaheadLine.match /^\#\s(.*)$/
					description += matches[1].replace(
						'}', ''
					).trim() + ' '

					lookaheadIndex += 1

				# } Key what we've found by filename.
				(hookInformation[filename] ?= []).push

					description: description
					name: hookName

	# } Output the hook information.
	alphabetical = Object.keys(hookInformation).sort()
	for filename in alphabetical
		hooks = hookInformation[filename]

		# } Top-level list: filenames
		markdown += """

Invoked in [#{filename}](./#{filename.replace /(coffee|js)/, 'html'}):

"""

		# } Second-level list: hook names and descriptions.
		for {name, description} in hooks

			packages = packagesImplementingHook name

			markdown += """

* ## `#{name}`

\t <h5>#{description}</h5>

"""

			continue if packages.length is 0

			for package_ in packages

				links = []
				for {type, filename} in package_.typesAndFilenames

					links.push """
<a href="./#{
	filename.replace /\.(js|coffee)$/, '.html'
}\#implementshook#{
	name.toLowerCase()
}">#{type}</a>
"""

				markdown += """

\t* #{
	package_.name.replace /\/index$/, ''
} (#{
	links.join ', '
})

"""

	fs.writeFileSync 'documentation/hooks.md', markdown

# Generate TODO documentation.
generateTodoDocumentation = do ->

	markdown = '''

# TODO list

Shrub -- like any project -- always presents a path for improvement. This is
a dynamically generated listing of TODO items, each with a line of code
context.


'''

	todoInformation = {}
	for filename, {lines} of sources

		for line, index in lines

			# } Find the comment with the TODO, and retrieve the description.
			if matches = line.match /^\#\s(?:}\s+)?`TODO`:\s(.*)$/

				# } Look ahead until we hit an empty line; all following lines
				# } until then are the TODO description.
				description = matches[1] + ' '
				lookaheadIndex = index + 1
				while lookaheadLine = lines[lookaheadIndex]
					break unless (matches = lookaheadLine.match /^\#\s(.*)$/)?

					description += matches[1].replace(
						'}', ''
					).trim() + ' '

					lookaheadIndex += 1

				# Look ahead until we find a non-comment. We'll use this as
				# context for the TODO item.
				while lines[lookaheadIndex].match /^(\#|$)/
					lookaheadIndex += 1

				(todoInformation[filename] ?= []).push

					context: lines[lookaheadIndex]
					description: description

	# } Output the TODO information.
	alphabetical = Object.keys(todoInformation).sort()
	for filename in alphabetical
		todos = todoInformation[filename]

		# } Top-level list: filenames
		markdown += """

[#{filename}](./#{filename.replace /(coffee|js)/, 'html'})

"""

		# } Second-level list: TODO descriptions.
		for {context, description} in todos

			markdown += """

* #### `#{context}`

\t #{description}

"""

	fs.writeFileSync 'documentation/todos.md', markdown

# Generate package documentation.
generatePackageDocumentation = do ->

	markdown = '''

# Package overview

Packages are how Shrub organizes functionality. Packages may be provided for
the server or the client (or both).

This page provides a listing of packages in this project, along with a short
description of the functionality they provide.


'''

	for type, package_ of packageInformation
		for name, {filename} of package_
			{commentLines} = sources[filename]

			packageInformation[type][name].description = ''

			# } Nothing to do if there are no comments.
			continue unless commentLines.length > 0

			# } Jump to the second comment.
			index = 0
			index += 1 while commentLines[index] is ''
			continue if index is commentLines.length
			index += 2
			continue if index is commentLines.length

			# } Get everything until the comment ends as the package
			# } description.
			description = ''
			while true
				break if (lookaheadLine = commentLines[index]) is ''
				break unless lookaheadLine?

				matches = lookaheadLine.match /^\#\s(.*)$/
				description += matches[1].replace(
					'}', ''
				).trim() + ' '

				index += 1

			packageInformation[type][name].description = description.trim()

	# } Output the package information.
	for type in ['client', 'server']
		alphabetical = Object.keys(packageInformation[type]).sort()

		humanizeType = client: 'Client-side', server: 'Server-side'

		# } Top-level list: type
		markdown += """

###{humanizeType[type]}

"""

		for packageName in alphabetical
			{description, filename} = packageInformation[type][packageName]

			# } Second-level list: packages with descriptions.
			markdown += """

* ### [`#{packageName}`](./#{filename.replace /(coffee|js)/, 'html'})

\t <h4>#{description}</h4>

"""

	fs.writeFileSync 'documentation/packages.md', markdown
