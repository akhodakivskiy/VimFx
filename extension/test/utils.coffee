# This file provides some handy helpers for testing.

Vim = require('../lib/vim')

stub = (obj, method, fn) ->
  originalFn = obj[method]
  obj[method] = fn
  return -> obj[method] = originalFn

class MockMessageManager
  constructor: ->
    @sendAsyncMessageCalls      = 0
    @addMessageListenerCalls    = 0
    @removeMessageListenerCalls = 0

  sendAsyncMessage: -> @sendAsyncMessageCalls += 1
  addMessageListener: -> @addMessageListenerCalls += 1
  removeMessageListener: -> @removeMessageListenerCalls += 1

class MockVim extends Vim
  constructor: (@_messageManager = null) ->

module.exports = {
  stub
  MockMessageManager
  MockVim
}
