path = require 'path'
child_process = require 'child_process'

tcpPortUsed = require 'tcp-port-used'

bootstrap = require 'bootstrap'

shrubConfig = require 'shrub-config'

exports.pkgmanRegister = (registrar) ->

	# ## Implements hook `gruntConfig`
	registrar.registerHook 'gruntConfig', (gruntConfig) ->

		{grunt} = gruntConfig

		gruntConfig.coffeelint ?= {}

		gruntConfig.coffeelint.shrub =

			files: [
				src: [
					'**/*.coffee'
					'!node_modules/**/*.coffee'
				]
			]

			options:

				arrow_spacing: level: 'error'

				camel_case_classes: level: 'error'

				coffeescript_error: level: 'error'

				colon_assignment_spacing:
					level: 'error'
					spacing:
						left: 0
						right: 1

				cyclomatic_complexity:
					value: 10
					level: 'ignore'

				duplicate_key: level: 'error'

				empty_constructor_needs_parens: level: 'ignore'

				ensure_comprehensions: level: 'warn'

				indentation:
					value: 1
					level: 'error'

				line_endings:
					level: 'ignore'
					value: 'unix'

				max_line_length:
					value: 80
					level: 'ignore'
					limitcOmments: true

				missing_fat_arrows:
					level: 'ignore'

				newlines_after_classes:
					value: 3
					level: 'ignore'

				no_backticks: level: 'warn'

				no_debugger: level: 'warn'

				no_empty_functions: level: 'ignore'

				no_empty_param_list: level: 'error'

				no_implicit_braces:
					level: 'ignore'
					strict: true

				no_implicit_parens:
					strict: true
					level: 'ignore'

				no_interpolation_in_single_quotes: level: 'ignore'

				no_plusplus: level: 'ignore'

				no_stand_alone_at: level: 'error'

				no_tabs: level: 'ignore'

				no_throwing_strings: level: 'error'

				no_trailing_semicolons: level: 'error'

				no_trailing_whitespace:
					level: 'error'
					allowed_in_comments: false
					allowed_in_empty_lines: true

				no_unnecessary_double_quotes: level: 'warn'

				no_unnecessary_fat_arrows: level: 'error'

				non_empty_constructor_needs_parens: level: 'ignore'

				prefer_english_operator:
					level: 'error'
					doubleNotLevel: 'ignore'

				space_operators: level: 'error'

				spacing_after_comma: level: 'error'

				transform_messes_up_line_numbers: level: 'warn'

		gruntConfig.shrub.tasks['lint'] = [
			'coffeelint:shrub'
		]

		grunt.loadNpmTasks 'grunt-coffeelint'
