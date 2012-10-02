"use strict"

{ utils: Cu } = Components

Cu.import "resource://gre/modules/Services.jsm"
Cu.import "resource://gre/modules/AddonManager.jsm"

# Populate the global namespace with console, require, and include
do (global = this) ->
  baseURI = Services.io.newURI __SCRIPT_URI_SPEC__, null, null
  getResourceURI = (path) -> Services.io.newURI path, null, baseURI

  include = (src, scope = {}) ->
    try
      uri = getResourceURI "packages/#{ src }.js"
      Services.scriptloader.loadSubScript uri.spec, scope
    catch error
      uri = getResourceURI src
      Services.scriptloader.loadSubScript uri.spec, scope

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

      include src, scope

      return modules[src] = scope.exports;

  global.include = include
  global.require = require
  global.getResourceURI = getResourceURI

# Include into global scope
include("includes/#{ name }.js", this) for name in [
  'chrome',
  'console',
  'unload', 
  'window-utils',
]

{ loadCss }             = require 'utils'
{ addEventListeners }   = require 'events'
{ getPref
, installPrefObserver } = require 'prefs'
{ setButtonDefaultPosition
, addToolbarButton }    = require 'button'

# Firefox will call this method on startup/enabling
startup = (data, reason) ->
  if reason = ADDON_INSTALL
    setButtonDefaultPosition getPref('button_id'), 'nav-bar', 'bookmarks-menu-button-container'

  loadCss 'style'
  watchWindows addEventListeners, 'navigator:browser'
  watchWindows addToolbarButton, 'navigator:browser'
  installPrefObserver()

# Firefox will call this method on shutdown/disabling
shutdown = (data, reason) ->
  # Don't bother to clean up if the browser is shutting down
  if reason != APP_SHUTDOWN
    unload()
