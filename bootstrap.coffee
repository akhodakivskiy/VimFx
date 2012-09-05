"use strict"

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

# Populate the global namespace with console, require, and include
do (global = this) ->
  tools = {}
  Cu.import "resource://gre/modules/Services.jsm", tools
  baseURI = tools.Services.io.newURI __SCRIPT_URI_SPEC__, null, null

  include = (src, scope = {}) ->
    try
      uri = tools.Services.io.newURI "packages/#{ src }.js", null, baseURI
      tools.Services.scriptloader.loadSubScript uri.spec, scope
    catch error
      uri = tools.Services.io.newURI src, null, baseURI
      tools.Services.scriptloader.loadSubScript uri.spec, scope

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

  Console = require("console").Console
  global.console = new Console "vimff"
  global.include = include
  global.require = require

{ loadCss, unloadCss }        = require 'utils'
{ createWindowEventTracker }  = require 'event-handlers'

tracker = createWindowEventTracker()

# Firefox will call this method on startup/enabling
startup = (data, reason) ->
  loadCss 'vimff'
  tracker.start()

# Firefox will call this method on shutdown/disabling
shutdown = (data, reason) ->
  tracker.stop()
  unloadCss 'vimff'
