'use strict'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Cu.import('resource://gre/modules/Services.jsm')

# Populate the global namespace with console, require, and include
do (global = this) ->
  loader = Cc['@mozilla.org/moz/jssubscript-loader;1'].getService(Ci.mozIJSSubScriptLoader)
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)

  # Loaded packages cache
  packages = {}

  # Load and cache package
  require = (name) ->
    if packages[name] is undefined
      scope = { require, exports: {} }
      try
        path = Services.io.newURI("packages/#{ name }.js", null, baseURI).spec
        loader.loadSubScript(path, scope)
        packages[name] = scope.exports
      catch error
        dump("Failed to load #{ name }: #{ error }\n")
        dump(error.stack)

    return packages[name]

  # Unload all packages
  release = ->
    for path, scope in packages
      for name, value in scope
        scope[name] = null
    packages = {}

  # Load native console API
  Cu.import("resource://gre/modules/devtools/Console.jsm")

  # Firefox will call this method on startup/enabling
  global.startup = (data, reason) ->
    # Requires for startup/install
    { loadCss }             = require 'utils'
    { addEventListeners
    , vimBucket }           = require 'events'
    { getPref }             = require 'prefs'
    { setButtonInstallPosition
    , addToolbarButton }    = require 'button'
    options                 = require 'options'
    { watchWindows }        = require 'window-utils'
    { unload }              = require 'unload'

    if reason == ADDON_INSTALL
      # Position the toolbar button right before the default Bookmarks button
      # If Bookmarks button is hidden - then VimFx button will be appended to the toolbar
      setButtonInstallPosition('nav-bar', 'bookmarks-menu-button-container')

    loadCss('style')

    options.observe()

    watchWindows(addEventListeners, 'navigator:browser')
    watchWindows(addToolbarButton.bind(undefined, vimBucket), 'navigator:browser')

    unload(release)

  # Firefox will call this method on shutdown/disabling
  global.shutdown = (data, reason) ->
    # Don't bother to clean up if the browser is shutting down
    if reason != APP_SHUTDOWN
      { unload } = require 'unload'
      unload()

  global.install = (data, reason) ->

  global.uninstall = (data, reason) ->
