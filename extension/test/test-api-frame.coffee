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

testUtils       = require('./utils')
createConfigAPI = require('../lib/api-frame')

{throws} = testUtils

exports['test exports'] = (assert, $vim) ->
  vimfx = createConfigAPI($vim)

  assert.equal(typeof vimfx.listen, 'function', 'listen')
  assert.equal(typeof vimfx.setHintMatcher, 'function', 'setHintMatcher')

exports['test vimfx.listen'] = (assert, $vim, teardown) ->
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

exports['test vimfx.setHintMatcher'] = (assert, $vim) ->
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

exports['test vimfx.listen errors'] = (assert, $vim) ->
  vimfx = createConfigAPI($vim)

  throws(assert, /message string/i, 'undefined', ->
    vimfx.listen()
  )

  throws(assert, /message string/i, 'false', ->
    vimfx.listen(false)
  )

  throws(assert, /listener function/i, 'undefined', ->
    vimfx.listen('message')
  )

  throws(assert, /listener function/i, 'false', ->
    vimfx.listen('message', false)
  )

exports['test vimfx.setHintMatcher errors'] = (assert, $vim) ->
  vimfx = createConfigAPI($vim)

  throws(assert, /function/i, 'undefined', ->
    vimfx.setHintMatcher()
  )

  throws(assert, /function/i, 'false', ->
    vimfx.setHintMatcher(false)
  )
