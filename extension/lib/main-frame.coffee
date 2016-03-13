###
# Copyright Simon Lydell 2015.
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

# This file is the equivalent of main.coffee, but for frame scripts.

commands = require('./commands-frame')
config = require('./config')
createConfigAPI = require('./api-frame')
FrameEventManager = require('./events-frame')
messageManager = require('./message-manager')
prefs = require('./prefs')
VimFrame = require('./vim-frame')
# @if TESTS
test = require('../test/index')
# @endif

module.exports = ->
  {content} = FRAME_SCRIPT_ENVIRONMENT
  vim = new VimFrame(content)

  eventManager = new FrameEventManager(vim)
  eventManager.addListeners()
  eventManager.sendFocusType({ignore: ['none']})

  messageManager.listen('runCommand', ({name, data}, callback) ->
    result = commands[name](Object.assign({vim}, data))
    callback?(result)
  )

  shutdownHandlers = []
  onShutdown = (fn) -> shutdownHandlers.push(fn)

  loadConfig = ->
    configDir = prefs.get('config_file_directory')
    scope = {vimfx: createConfigAPI(vim, onShutdown)}
    error = config.loadFile(configDir, 'frame.js', scope)
    return error

  # main.coffee cannot know when the 'loadConfig' listener below is ready, so
  # run `loadConfig` manually on startup.
  loadConfig()

  messageManager.listen('loadConfig', (data, callback) ->
    error = loadConfig()
    callback(not error)
  )

  messageManager.listen('unloadConfig', ->
    for shutdownHandler in shutdownHandlers
      try
        shutdownHandler()
      catch error
        console.error("VimFx: `vimfx.on('shutdown')` error in frame.js", error)
    shutdownHandlers = []
  )

  # @if TESTS
  messageManager.send('runTests', null, (ok) -> test(vim) if ok)
  # @endif
