###
# Copyright Simon Lydell 2016.
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

assert = require('./assert')
testUtils = require('./utils')
createConfigAPI = require('../lib/api-frame')

exports['test exports'] = ($vim) ->
  vimfx = createConfigAPI($vim)

  assert.equal(typeof vimfx.listen, 'function', 'listen')
  assert.equal(typeof vimfx.setHintMatcher, 'function', 'setHintMatcher')
  assert.equal(typeof vimfx.getMarkerElement, 'function', 'getMarkerElement')

exports['test vimfx.listen'] = ($vim, teardown) ->
  shutdownHandlers = []
  onShutdown = (fn) -> shutdownHandlers.push(fn)
  vimfx = createConfigAPI($vim, onShutdown)

  resets = []
  teardown(->
    reset() for reset in resets
    return
  )

  messageManager = new testUtils.MockMessageManager()
  for name, fn of messageManager when typeof fn == 'function'
    resets.push(
      testUtils.stub(FRAME_SCRIPT_ENVIRONMENT, name, fn.bind(messageManager))
    )

  vimfx.listen('message', ->)
  assert.equal(messageManager.sendAsyncMessageCalls, 0)
  assert.equal(messageManager.addMessageListenerCalls, 1)
  assert.equal(messageManager.removeMessageListenerCalls, 0)

  assert.equal(shutdownHandlers.length, 1)
  shutdownHandlers[0]()
  assert.equal(messageManager.sendAsyncMessageCalls, 0)
  assert.equal(messageManager.addMessageListenerCalls, 1)
  assert.equal(messageManager.removeMessageListenerCalls, 1)

exports['test vimfx.setHintMatcher'] = ($vim) ->
  shutdownHandlers = []
  onShutdown = (fn) -> shutdownHandlers.push(fn)
  vimfx = createConfigAPI($vim, onShutdown)

  assert.ok(not $vim.hintMatcher)

  hintMatcher = ->
  vimfx.setHintMatcher(hintMatcher)
  assert.equal($vim.hintMatcher, hintMatcher)

  assert.equal(shutdownHandlers.length, 1)
  shutdownHandlers[0]()
  assert.ok(not $vim.hintMatcher)

exports['test vimfx.getMarkerElement'] = ($vim, teardown) ->
  teardown(->
    $vim.state.markerElements = []
  )

  vimfx = createConfigAPI($vim)
  element = {}
  $vim.state.markerElements = [{element}]

  assert.equal(vimfx.getMarkerElement(0), element)
  assert.equal(vimfx.getMarkerElement(1), null)
  assert.equal(vimfx.getMarkerElement(null), null)

  $vim.state.markerElements = []
  assert.equal(vimfx.getMarkerElement(0), null)

exports['test vimfx.listen errors'] = ($vim) ->
  vimfx = createConfigAPI($vim)

  assert.throws(/message string/i, 'undefined', ->
    vimfx.listen()
  )

  assert.throws(/message string/i, 'false', ->
    vimfx.listen(false)
  )

  assert.throws(/listener function/i, 'undefined', ->
    vimfx.listen('message')
  )

  assert.throws(/listener function/i, 'false', ->
    vimfx.listen('message', false)
  )

exports['test vimfx.setHintMatcher errors'] = ($vim) ->
  vimfx = createConfigAPI($vim)

  assert.throws(/function/i, 'undefined', ->
    vimfx.setHintMatcher()
  )

  assert.throws(/function/i, 'false', ->
    vimfx.setHintMatcher(false)
  )
