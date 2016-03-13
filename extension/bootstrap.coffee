###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

# This file boots the main VimFx process, as well as each frame script. It tries
# to do the minimum amount of things to run main.coffee, or main-frame.coffee
# for frame scripts. It defines a few global variables, and sets up a
# Node.js-style `require` module loader.

# `bootstrap.js` files of different add-ons do _not_ share scope. However, frame
# scripts for the same `<browser>` but from different add-ons _do_ share scope.
# In order not to pollute that global scope in frame scripts, everything is done
# in an IIFE here, and the `global` variable is handled with care.

do (global = this) ->

  {classes: Cc, interfaces: Ci, utils: Cu} = Components
  ADDON_PATH = 'chrome://vimfx'
  IS_FRAME_SCRIPT = (typeof content != 'undefined')
  BUILD_TIME = do -> # @echo BUILD_TIME
  REQUIRE_DATA = do -> # @echo REQUIRE_DATA

  unless IS_FRAME_SCRIPT
    # Make `Services` and `console` available globally, just like they are in
    # frame scripts by default.
    Cu.import('resource://gre/modules/Services.jsm')
    try
      # TODO: Only use this path when Firefox 44 is released.
      Cu.import('resource://gre/modules/Console.jsm')
    catch
      Cu.import('resource://gre/modules/devtools/Console.jsm')

  shutdownHandlers = []

  dirname = (uri) -> uri.split('/')[...-1].join('/') or '.'

  require = (path, moduleRoot = '.', dir = '.') ->
    unless path[0] == '.'
      # Allow `require('module/lib/foo')` in additon to `require('module')`.
      [match, name, subPath] = path.match(///^ ([^/]+) (?: /(.+) )? ///)
      base = REQUIRE_DATA[moduleRoot]?[name] ? moduleRoot
      dir  = "#{base}/node_modules/#{name}"
      main = REQUIRE_DATA[dir]?['']
      path = subPath ? main ? 'index'
      moduleRoot = dir

    prefix = "#{ADDON_PATH}/content"
    uri = "#{prefix}/#{dir}/#{path}.js"
    normalizedUri = Services.io.newURI(uri, null, null).spec
    currentDir = dirname(".#{normalizedUri[prefix.length..]}")

    unless require.scopes[normalizedUri]?
      module = {
        exports: {}
        onShutdown: (fn) -> shutdownHandlers.push(fn)
      }
      require.scopes[normalizedUri] = scope = {
        require: (path) -> require.call(null, path, moduleRoot, currentDir)
        module, exports: module.exports
        Cc, Ci, Cu
        ADDON_PATH, BUILD_TIME
        IS_FRAME_SCRIPT
        FRAME_SCRIPT_ENVIRONMENT: if IS_FRAME_SCRIPT then global else null
      }
      Services.scriptloader.loadSubScript(normalizedUri, scope, 'UTF-8')

    return require.scopes[normalizedUri].module.exports

  require.scopes = {}

  startup = (args...) ->
    main = if IS_FRAME_SCRIPT then './lib/main-frame' else './lib/main'
    require(main)(args...)

  shutdown = ->
    for shutdownHandler in shutdownHandlers
      try
        shutdownHandler()
      catch error
        Cu.reportError(error)
    shutdownHandlers = []

    # Release everything in `require`d modules. This must be done _after_ all
    # shutdownHandlers, since they use variables in these scopes.
    for path, scope of require.scopes
      for name of scope
        scope[name] = null
    require.scopes = {}

  if IS_FRAME_SCRIPT
    messageManager = require('./lib/message-manager')

    # Tell the main process that this frame script was created, and ask if
    # anything should be done in this frame.
    messageManager.send('tabCreated', null, (ok) ->
      # After dragging a tab from one window to another, `content` might have
      # been set to `null` by Firefox when this runs. If so, simply return.
      return unless ok and content?

      startup()

      messageManager.listenOnce('shutdown', shutdown)
    )
  else
    global.startup = startup
    global.shutdown = shutdown
    global.install = ->
    global.uninstall = ->
