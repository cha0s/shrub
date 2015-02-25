# UI - Markdown

    marked = require 'marked'

    exports.pkgmanRegister = (registrar) ->

#### Implements hook `shrubAngularFilter`

      registrar.registerHook 'shrubAngularFilter', -> ->

        (input, sanitize = true) -> marked input, sanitize: sanitize
