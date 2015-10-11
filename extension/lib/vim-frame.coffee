###
# Copyright Anton Khodakivskiy 2012, 2013.
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

# This file is the equivalent to vim.coffee. `vim.window` is called
# `vim.content` to be consistent with Firefox’s frame script terminology and to
# avoid confusion about what it represents. There is one `VimFrame` instance for
# each tab. It mostly tries to mimic the `Vim` class in vim.coffee, but also
# keeps track of web page state. `VimFrame` is not part of the public API.

messageManager = require('./message-manager')
utils          = require('./utils')

class VimFrame
  constructor: (@content) ->
    @mode = 'normal'

    messageManager.listen('modeChange', ({ mode }) ->
      @mode = mode
    )

    @resetState()

  resetState: ->
    @state =
      lastInteraction:          null
      lastAutofocusPrevention:  null
      scrollableElements:       new WeakSet()
      lastFocusedTextInput:     null

  options: (prefs) -> messageManager.get('options', {prefs})

  enterMode: (@mode, args...) ->
    messageManager.send('vimMethod', {
      method: 'enterMode'
      args: [@mode, args...]
    })

  onInput: (event) ->
    eventSubset = {}
    for key in ['key', 'code', 'altKey', 'ctrlKey', 'metaKey', 'shiftKey']
      eventSubset[key] = event[key]
    args = [eventSubset, utils.getFocusType(event), {isFrameEvent: true}]
    suppress = messageManager.get('vimMethodSync', {method: '_onInput', args})
    utils.suppressEvent(event) if suppress
    messageManager.send('onInput-frame', { suppress })

  notify: (args...) ->
    messageManager.send('vimMethod', {method: 'notify', args})

module.exports = VimFrame
