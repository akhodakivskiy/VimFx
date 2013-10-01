'use strict'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Cu.import('resource://gre/modules/Services.jsm')

# Populate the global namespace with console, require, and include
do (global = this) ->
  loader = Cc['@mozilla.org/moz/jssubscript-loader;1'].getService(Ci.mozIJSSubScriptLoader)
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)

  # Loaded packages cache
  packages = {}

  # To be loaded in a bit
  console = null

  # Load and cache package
  require = (name) ->
    if packages[name] is undefined
      scope = { console, require, exports: {} }
      try
        path = Services.io.newURI("packages/#{ name }.js", null, baseURI).spec
        loader.loadSubScript(path, scope)
        packages[name] = scope.exports
      catch error
        dump("Failed to load #{ name }: #{ error }\n")
        dump(error.stack)

    return packages[name]

  # Load up console that is defined above
  { console } = require 'console'

  # Unload all packages
  release = ->
    for path, scope in packages
      for name, value in scope
        scope[name] = null
    packages = {}

  # Firefox will call this method on startup/enabling
  global.startup = (data, reason) ->
    # Requires for startup/install
    { loadCss }             = require 'utils'
    { addEventListeners }   = require 'events'
    { getPref
    , initPrefValues }      = require 'prefs'
    { setButtonInstallPosition
    , addToolbarButton }    = require 'button'
    options                 = require 'options'
    { watchWindows }        = require 'window-utils'
    { unload }              = require 'unload'

    if reason == ADDON_INSTALL
      # Position the toolbar button right before the default Bookmarks button
      # If Bookmarks button is hidden - then VimFx button will be appended to the toolbar
      setButtonInstallPosition('nav-bar', 'bookmarks-menu-button-container')

    # Write default preference values on install
    initPrefValues()

    loadCss('style')

    options.observe()

    watchWindows(addEventListeners, 'navigator:browser')
    watchWindows(addToolbarButton, 'navigator:browser')

    unload(release)

  # Firefox will call this method on shutdown/disabling
  global.shutdown = (data, reason) ->
    # Don't bother to clean up if the browser is shutting down
    if reason != APP_SHUTDOWN
      { unload } = require 'unload'
      unload()

  global.install = (data, reason) ->

  global.uninstall = (data, reason) ->
