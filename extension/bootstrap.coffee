'use strict'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Cu.import('resource://gre/modules/Services.jsm')
Cu.import('resource://gre/modules/AddonManager.jsm')

# Populate the global namespace with console, require, and include
do (global = this) ->
  loader = Cc['@mozilla.org/moz/jssubscript-loader;1'].getService(Ci.mozIJSSubScriptLoader)
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)

  include = (src, scope) ->
    try
      path = Services.io.newURI(src, null, baseURI).spec
      loader.loadSubScript(path, scope)
    catch error
      dump("Failed to load #{ src }: #{ error }\n")

    return scope


  modules = {}
  require = (src) ->
    if modules[src]
      return modules[src]
    else
      scope =
        require: require
        exports: {}

      include("packages/#{ src }.js", scope)

      return modules[src] = scope.exports

  release = ->
    for path, scope in modules
      for name, value in scope
        scope[name] = null
    modules = {}

  # Firefox will call this method on startup/enabling
  global.startup = (data, reason) ->
    # Requires for startup/install
    { loadCss }             = require 'utils'
    { addEventListeners }   = require 'events'
    { getPref }             = require 'prefs'
    { setButtonInstallPosition
    , addToolbarButton }    = require 'button'
    { watchWindows }        = require 'window-utils'
    { unload }              = require 'unload'

    if reason == ADDON_INSTALL
      # Position the toolbar button right before the default Bookmarks button
      # If Bookmarks button is hidden - then VimFx button will be appended to the toolbar
      setButtonInstallPosition 'nav-bar', 'bookmarks-menu-button-container'

    loadCss('style')

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
