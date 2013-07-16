"use strict"

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Cu.import("resource://gre/modules/Services.jsm")
Cu.import("resource://gre/modules/AddonManager.jsm")

# Populate the global namespace with console, require, and include
do (global = this) ->
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)
  getResourceURI = (path) -> Services.io.newURI(path, null, baseURI)

  loader = Cc["@mozilla.org/moz/jssubscript-loader;1"].getService(Ci.mozIJSSubScriptLoader)

  include = (src, scope = {}) ->
    try
      uri = getResourceURI(src)
      loader.loadSubScript(uri.spec, scope)
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
        include: include
        exports: {}

      include("packages/#{ src }.js", scope)

      return modules[src] = scope.exports

  global.include = include
  global.require = require
  global.getResourceURI = getResourceURI
  global.regexpEscape = (s) -> s and s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')

  # Include into global scope
  include("includes/#{ name }.js", global) for name in [
    'console'
    'unload'
  ]

  # Init localization `underscore` method
  global._ = require('l10n').l10n("vimfx.properties")

  # Requires for startup/install
  { loadCss }             = require 'utils'
  { addEventListeners }   = require 'events'
  { getPref }             = require 'prefs'
  { setButtonInstallPosition
  , addToolbarButton }    = require 'button'
  { watchWindows }        = require 'window-utils'

  # Firefox will call this method on startup/enabling
  global.startup = (data, reason) ->

    if reason == ADDON_INSTALL
      # Position the toolbar button right before the default Bookmarks button
      # If Bookmarks button is hidden - then VimFx button will be appended to the toolbar
      setButtonInstallPosition 'nav-bar', 'bookmarks-menu-button-container'

    loadCss('style')

    watchWindows(addEventListeners, 'navigator:browser')
    watchWindows(addToolbarButton, 'navigator:browser')

  # Firefox will call this method on shutdown/disabling
  global.shutdown = (data, reason) ->
    # Don't bother to clean up if the browser is shutting down
    if reason != APP_SHUTDOWN
      unload()

  global.install = (data, reason) ->

  global.uninstall = (data, reason) ->
