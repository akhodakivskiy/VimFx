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
      base = require.data[moduleRoot]?[name] ? moduleRoot
      dir  = "#{base}/node_modules/#{name}"
      main = require.data[dir]?['']
      path = subPath ? main ? 'index'
      moduleRoot = dir

    prefix = "#{ADDON_PATH}/content"
    uri = "#{prefix}/#{dir}/#{path}.js"
    normalizedUri = Services.io.newURI(uri, null, null).spec
    currentDir = dirname(".#{normalizedUri[prefix.length..]}")

    unless require.scopes[normalizedUri]?
      module =
        exports:    {}
        onShutdown: (fn) -> shutdownHandlers.push(fn)
      require.scopes[normalizedUri] = scope = {
        require: (path) -> require.call(null, path, moduleRoot, currentDir)
        module, exports: module.exports
        Cc, Ci, Cu
        ADDON_PATH
        IS_FRAME_SCRIPT
        FRAME_SCRIPT_ENVIRONMENT: if IS_FRAME_SCRIPT then global else null
      }
      Services.scriptloader.loadSubScript(normalizedUri, scope, 'UTF-8')

    return require.scopes[normalizedUri].module.exports

  require.scopes = {}

  global.startup = (args...) ->
    # `require` cannot be used outside of `startup` (except for in frame
    # scripts), so wait setting `require.data` until here.
    require.data = require('./require-data')

    main = if IS_FRAME_SCRIPT then './lib/main-frame' else './lib/main'
    require(main)(args...)

  global.shutdown = ->
    require('./lib/message-manager').send('shutdown') unless IS_FRAME_SCRIPT

    for shutdownHandler in shutdownHandlers
      try
        shutdownHandler()
      catch error
        Cu.reportError(error)
    shutdownHandlers = null

    # Release everything in `require`d modules. This must be done _after_ all
    # shutdownHandlers, since they use variables in these scopes.
    for path, scope of require.scopes
      for name of scope
        scope[name] = null
    require.scopes = null

  global.install = ->

  global.uninstall = ->

  if IS_FRAME_SCRIPT
    messageManager = require('./lib/message-manager')

    # Tell the main process that this frame script was created, and ask if
    # anything should be done in this frame.
    messageManager.send('tabCreated', null, (ok) ->
      return unless ok

      global.startup()

      # When updating the add-on, the previous version is going to shut down at
      # the same time as the new version starts up. Add the shutdown listener in
      # the next tick to prevent the previous version from triggering it.
      content.setTimeout((->
        messageManager.listenOnce('shutdown', global.shutdown)
      ), 0)
    )
