'use strict'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Cu.import('resource://gre/modules/Services.jsm')
Cu.import('resource://gre/modules/devtools/Console.jsm')

do (global = this) ->
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)

  # Loaded packages cache.
  packages = {}

  # Load and cache package.
  require = (name) ->
    unless packages[name]?
      scope = {require, exports: packages[name] = {}}
      try
        path = Services.io.newURI("packages/#{ name }.js", null, baseURI).spec
        Services.scriptloader.loadSubScript(path, scope)
      catch error
        dump("Failed to load #{ name }: #{ error }\n")
        dump(error.stack)

    return packages[name]

  # Unload all packages.
  release = ->
    for path, scope in packages
      for name, value in scope
        scope[name] = null
    packages = {}

  global.startup = (data, reason) ->
    { loadCss }             = require 'utils'
    { addEventListeners
    , vimBucket }           = require 'events'
    { getPref
    , setDefaultPrefs }     = require 'prefs'
    { setButtonInstallPosition
    , addToolbarButton }    = require 'button'
    options                 = require 'options'
    { watchWindows }        = require 'window-utils'
    { unloader }            = require 'unloader'

    setDefaultPrefs()

    if reason == ADDON_INSTALL
      # Position the toolbar button right before the default Bookmarks button.
      # If Bookmarks button is hidden the VimFx button will be appended to the
      # toolbar.
      setButtonInstallPosition('nav-bar', 'bookmarks-menu-button-container')

    loadCss('style')

    options.observe()

    watchWindows(addEventListeners, 'navigator:browser')
    watchWindows(addToolbarButton.bind(undefined, vimBucket),
                 'navigator:browser')

    unloader.add(release)

  global.shutdown = (data, reason) ->
    # Don't bother to clean up if the browser is shutting down.
    unless reason == APP_SHUTDOWN
      { unloader } = require 'unloader'
      unloader.unload()

  global.install = (data, reason) ->

  global.uninstall = (data, reason) ->
