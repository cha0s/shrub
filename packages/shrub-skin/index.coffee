# # Skin
#
# *Allows the visual aspects of the site to be controlled by skin packages.*
fs = require 'fs'
path = require 'path'

config = require 'config'
pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubConfigClient`.
  registrar.registerHook 'shrubConfigClient', ->

    skinAssets = {}
    for packagePath in pkgman.packagesImplementing 'shrubSkinAssets'
      skinAssets[packagePath] = exports.assets packagePath

    default: config.get 'packageConfig:shrub-skin:default'
    assets: skinAssets

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'path', 'shrubHttpMiddleware', (http) ->

    label: 'Skin path handling'
    middleware: [

      (req, res, next) ->

        # If we get here and it's a skin URL, it must be a 404 otherwise,
        # express/static would have picked it up already.
        return res.sendStatus 404 if req.path.match /^\/skin\//

        next()
    ]

  # #### Implements hook `shrubHttpMiddleware`.
  registrar.registerHook 'render', 'shrubHttpMiddleware', (http) ->

    label: 'Render skinned page HTML'
    middleware: [

      (req, res, next) ->

        return exports.renderAppHtml().then((html) ->
          req.delivery = html
          next()
        ).catch (error) -> next error

  ]

  # #### Implements hook `shrubConfigServer`.
  registrar.registerHook 'shrubConfigServer', ->

    # Default skin.
    default: 'shrub-skin-strapped'

# ## activeKey
#
# *Get the active skin's key*
exports.activeKey = -> config.get 'packageConfig:shrub-skin:default'

# ## gruntSkin
#
# *Helper function to copy skin assets. Configures a grunt task, e.g. if your
# skin is named `my-special-skin`, the configured task is named
# `my-special-skinCopy`. This is not automatically added to the build
# dependencies, you do it manually so you can control exactly when it
# happens.*
exports.gruntSkin = (gruntConfig, key) ->

  skinPath = path.dirname require.resolve key

  gruntConfig.clean ?= {}
  gruntConfig.copy ?= {}
  gruntConfig.watch ?= {}

  gruntConfig.configureTask 'clean', key, [
    "app/skin/#{key}"
  ]

  copyFiles = []

  copyFiles.push(
    expand: true
    cwd: "#{skinPath}/app"
    src: ["#{verbatim}/**/*"]
    dest: "app/skin/#{key}"
  ) for verbatim in ['css', 'fonts', 'img', 'js', 'lib']

  gruntConfig.configureTask 'copy', key, files: copyFiles

  gruntConfig.configureTask(
    'watch', "#{key}Copy"

    files: copyFiles.concat(
      src: "template/**/*"
    ).map(
      (copyFile) -> "#{skinPath}/app/#{copyFile.src}"
    )
    tasks: [
      "newer:copy:#{key}"
    ]
    options: livereload: true
  )

# ## renderAppHtml
#
# *Render the application HTML.*
exports.renderAppHtml = ->

  Promise = require 'bluebird'

  cheerio = require 'cheerio'

  assets = require 'shrub-assets'

  skinKey = exports.activeKey()
  skinDirectory = exports.skinDirectory skinKey

  environmentKey = if 'production' is process.env.NODE_ENV
    'production'
  else
    'default'

  # Read the app HTML.
  readFile = Promise.promisify fs.readFile, fs
  readFile(
    "#{skinDirectory}/app/template/app.html", encoding: 'utf8'
  ).then (html) ->

    $ = cheerio.load html

    pkgman.invoke 'skinRenderAppHtml', $

    $head = $('head')
    $body = $('body')

    # Inject the application-level assets first.
    appAssets = assets.assets()

    $head.append $('<link />').attr(
      type: 'text/css'
      rel: 'styleSheet'
      href: styleSheet
    ) for styleSheet in appAssets.styleSheets

    $body.append $('<script />').attr(
      src: script
    ) for script in appAssets.scripts

    # Inject the skin-level assets.
    skinAssets = exports.assets skinKey

    $head.append $('<link />').attr(
      class: 'skin'
      type: 'text/css'
      rel: 'stylesheet'
      href: "/skin/#{skinKey}/#{styleSheet}"
    ) for styleSheet in skinAssets.styleSheets[environmentKey] ? []

    $body.append $('<script />').attr(
      class: 'skin'
      src: "/skin/#{skinKey}/#{script}"
    ) for script in skinAssets.scripts[environmentKey] ? []

    # Return the full HTML.
    return $.html()

# ## skinDirectory
#
# * (String) `key` - The skin key.
#
# *Get the directory a skin lives within.*
exports.skinDirectory = (key) -> path.dirname require.resolve key

# ## assets
#
# * (String) `key` - The skin key.
#
# *Get the assets for a skin.*
#
# ###### TODO: This needs caching.
exports.assets = (skinKey) ->

  glob = require 'simple-glob'
  pkgman = require 'pkgman'

  skinPath = path.dirname require.resolve skinKey
  skinModule = require skinKey

  # Read in all the templates.
  templates = {}
  for templatePath in glob cwd: "#{skinPath}/app/template", [
    '**/*.html', '!app.html'
  ]

    # Strip out most of the unnecessary whitespace.
    templates[templatePath] = fs.readFileSync(
      "#{skinPath}/app/template/#{templatePath}"
    ).toString('utf8').replace /\s+/g, ' '

  # Assets currently default to .js/.css for default and .min.js and .min.css
  # for production.
  skinAssets =

    templates: templates

    scripts:

      default: glob cwd: "#{skinPath}/app", [
        'js/**/*.js', '!js/**/*.min.js'
      ]

      production: glob cwd: "#{skinPath}/app", [
        'js/**/*.min.js'
      ]

    styleSheets:

      default: glob cwd: "#{skinPath}/app", [
        'css/**/*.css', '!css/**/*.min.css'
      ]

      production: glob cwd: "#{skinPath}/app", [
        'css/**/*.min.css'
      ]

  # Make script and stylesheet paths absolute.
  for type in ['scripts', 'styleSheets']
    for env in ['default', 'production']
      for asset, i in skinAssets[type][env]
        skinAssets[type][env][i] = "/#{asset}"

  # #### Invoke hook `shrubSkinAssets`.
  pkgman.invokePackage skinKey, 'shrubSkinAssets', skinAssets

  return skinAssets
