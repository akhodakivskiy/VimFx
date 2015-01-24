###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014.
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

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Cu.import('resource://gre/modules/Services.jsm')
Cu.import('resource://gre/modules/devtools/Console.jsm')

shutdownHandlers = []

createURI = (path, base = null) -> Services.io.newURI(path, null, base)
baseURI   = createURI(__SCRIPT_URI_SPEC__)

# Everything up to the first `!` is the absolute path to the .xpi.
dirname = (uri) -> uri.match(///^ [^!]+!/ (.+) /[^/]+ $///)[1]

require = (path, moduleRoot = '.', dir = '.') ->
  unless path[0] == '.'
    # Allow `require('module/lib/foo')` in additon to just `require('module')`.
    [ match, name, subPath ] = path.match(///^ ([^/]+) (?: /(.+) )? ///)
    base = require.data[moduleRoot]?[name] ? moduleRoot
    dir  = "#{ base }/node_modules/#{ name }"
    main = require.data[dir]?['']
    path = subPath ? main ? 'index'
    moduleRoot = dir

  fullPath = createURI("#{ dir }/#{ path }.js", baseURI).spec

  unless require.scopes[fullPath]?
    module =
      exports:    {}
      onShutdown: Function::call.bind(Array::push, shutdownHandlers)
    require.scopes[fullPath] = scope =
      require: (path) -> require(path, moduleRoot, "./#{ dirname(fullPath) }")
      module:  module
      exports: module.exports
    Services.scriptloader.loadSubScript(fullPath, scope)

  return require.scopes[fullPath].module.exports

require.scopes = {}
require.data   = require('./require-data')

do (global = this) ->

  global.startup = require('./lib/main')

  global.shutdown = (data, reason) ->
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

  global.install = (data, reason) ->

  global.uninstall = (data, reason) ->
