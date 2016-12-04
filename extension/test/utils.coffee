###
# Copyright Simon Lydell 2015, 2016.
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
