"use strict"

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

((global) ->

  tools = {}
  Cu.import "resource://gre/modules/Services.jsm", tools
  baseURI = tools.Services.io.newURI __SCRIPT_URI_SPEC__, null, null

  modules = {}
  global.require = (src) ->
    if modules[src]
      return modules[src]
    else
      scope = 
        require: global.require,
        exports: {}

      try
        uri = tools.Services.io.newURI "packages/" + src + ".js", null, baseURI
        tools.Services.scriptloader.loadSubScript uri.spec, scope
      catch error
        uri = tools.Services.io.newURI src, null, baseURI
        tools.Services.scriptloader.loadSubScript uri.spec, scope

      return modules[src] = scope.exports;

  global.include = (src) ->
    uri = tools.Services.io.newURI src, null, baseUri
    tools.Services.scriptloader.loadSubScript uri.spec, global

  Console = global.require("console").Console
  global.console = new Console "vimroll"

)(this);

startup = (data, reason) ->

shutdown = (data, reason) ->
