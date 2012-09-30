"use strict"

{ utils: Cu } = Components

Cu.import "resource://gre/modules/Services.jsm"

# Populate the global namespace with console, require, and include
do (global = this) ->
  baseURI = Services.io.newURI __SCRIPT_URI_SPEC__, null, null

  include = (src, scope = {}) ->
    try
      uri = Services.io.newURI "packages/#{ src }.js", null, baseURI
      Services.scriptloader.loadSubScript uri.spec, scope
    catch error
      uri = Services.io.newURI src, null, baseURI
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

# Include into global scope
include("includes/#{ name }.js", this) for name in [
  'chrome',
  'console',
  'unload', 
  'window-utils',
]

{ loadCss } = require 'utils'
{ watcher } = require 'event-handlers'
{ getPref
, installPrefObserver } = require 'prefs'

# Firefox will call this method on startup/enabling
startup = (data, reason) ->
  loadCss 'vimff'
  watchWindows watcher, 'navigator:browser'
  installPrefObserver()

# Firefox will call this method on shutdown/disabling
shutdown = (data, reason) ->
  # Don't bother to clean up if the browser is shutting down
  if reason != APP_SHUTDOWN
    unload()
