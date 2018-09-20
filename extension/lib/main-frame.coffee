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
    scope = {
      vimfx: createConfigAPI(vim, onShutdown)
      content: content
    }
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
