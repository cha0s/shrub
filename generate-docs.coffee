
# # Generate documentation
# 
# Various parts of the documentation are generated dynamically. This file
# parses the source files and generates the respective documentation files.

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
	sources[filename] = fs.readFileSync filename, encoding: 'utf8'

# Generate hook documentation.
generateHookDocumentation = do ->
	
	markdown = """

# Hooks

Shrub implements message passing between packages through a hook system. Hooks
may be invoked with [pkgman.invoke()](./client/modules/pkgman.html), and are
implemented in packages by prefixing a `$` to the hook name.

For instance, if we are implementing a package and want to implement the
`httpListening` hook, our code would look like:

	exports.$httpListening = ->
		
		# Your code goes here...

A dynamically generated listing of hooks follows.


"""
	
	hookInformation = {}
	for filename, source of sources
		
		commentLines = source.split(
			'\n'
		
		).map (line) -> if line.match /^\s+\#\s.+/ then line.trim() else ''
		
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
					description += matches[1].trim() + ' '
					
					lookaheadIndex += 1
				
				# } Key what we've found by filename.
				(hookInformation[filename] ?= []).push
				
					description: description
					name: hookName
	
	# } Output the hook information.			
	for filename, hooks of hookInformation
		
		# } Top-level list: filenames
		markdown += "* [#{
			filename
		}](./#{
			filename.replace /(coffee|js)/, 'html'
		}):\n\n"
		
		# } Second-level list: hook name and description.
		for {name, description} in hooks
			
			markdown += "\t* `#{
				name
			}` - #{
				description
			}\n\n"
		
	fs.writeFileSync "documentation/hooks.md", markdown
