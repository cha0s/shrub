# # Strapped
#
# *Shrub's default skin.*
path = require 'path'

shrubSkin = require 'shrub-skin'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `shrubNodemailerHtml`.
  registrar.registerHook 'shrubNodemailerHtml', ($body, html, $) ->

    $('.container > .main', $body).html html

    $body.find('.navbar-toggle, .navbar-collapse').remove()
    $body.find('[data-shrub-ui-messages]').remove()

    $body.find('script').remove()

    $('noscript', $body).remove()

  # #### Implements hook `shrubSkinAssets`.
  registrar.registerHook 'shrubSkinAssets', (assets) ->

    # Add our future-compiled LESS style sheets.
    assets.styleSheets.default.push '/css/style.css'
    assets.styleSheets.production.push '/css/style.css'

  # #### Implements hook `shrubGruntConfig`.
  registrar.registerHook 'shrubGruntConfig', (gruntConfig) ->

    gruntConfig.less ?= {}

    shrubSkin.gruntSkin gruntConfig, 'shrub-skin-strapped'

    gruntConfig.configureTask 'less', 'shrub-skin-strapped', files: [
      src: [
        "#{__dirname}/app/less/style.less"
      ]
      dest: 'app/skin/shrub-skin-strapped/css/style.css'
    ]

    gruntConfig.configureTask(
      'watch', 'shrub-skin-strappedLess'

      files: [
        "#{__dirname}/app/less/style.less"
      ]
      tasks: [
        'newer:less:shrub-skin-strapped'
      ]
      options: livereload: true
    )

    gruntConfig.registerTask 'build:shrub-skin-strapped', [
      'clean:shrub-skin-strapped'
      'newer:copy:shrub-skin-strapped'
      'less:shrub-skin-strapped'
    ]

    gruntConfig.registerTask 'build', ['build:shrub-skin-strapped']

    gruntConfig.loadNpmTasks ['grunt-contrib-less']