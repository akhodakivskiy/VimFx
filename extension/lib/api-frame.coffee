# This file defines VimFx’s config file API, for the frame script.

messageManager = require('./message-manager')

createConfigAPI = (vim, onShutdown = module.onShutdown) -> {
  listen: (message, listener) ->
    unless typeof message == 'string'
      throw new Error(
        "VimFx: The first argument must be a message string. Got: #{message}"
      )
    unless typeof listener == 'function'
      throw new Error(
        "VimFx: The second argument must be a listener function.
         Got: #{listener}"
      )
    messageManager.listen(message, listener, {
      prefix: 'config:'
      onShutdown
    })

  setHintMatcher: (hintMatcher) ->
    unless typeof hintMatcher == 'function'
      throw new Error(
        "VimFx: A hint matcher must be a function. Got: #{hintMatcher}"
      )
    vim.hintMatcher = hintMatcher
    onShutdown(-> vim.hintMatcher = null)

  getMarkerElement: (id) ->
    data = vim.state.markerElements[id]
    return if data then data.element else null
}

module.exports = createConfigAPI
