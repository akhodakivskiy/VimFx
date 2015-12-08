###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014, 2015.
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

messageManager     = require('./message-manager')
ScrollableElements = require('./scrollable-elements')
utils              = require('./utils')

class VimFrame
  constructor: (@content) ->
    @mode = 'normal'

    @resetState()

    messageManager.listen('modeChange', ({mode}) =>
      @mode = mode
    )

    messageManager.listen('markPageInteraction',
                          @markPageInteraction.bind(this))

  # If the target is the topmost document, reset everything. Otherwise filter
  # out elements belonging to the target frame. On some sites, such as Gmail,
  # some elements might be dead at this point.
  resetState: (target = @content.document) ->
    if target == @content.document
      @state =
        hasInteraction:       false
        shouldRefocus:        false
        marks:                {}
        explicitBodyFocus:    false
        hasFocusedTextInput:  false
        lastFocusedTextInput: null
        scrollableElements:   new ScrollableElements(@content)
        markerElements:       []
        inputs:               null

    else
      isDead = (element) ->
        return Cu.isDeadWrapper(element) or element.ownerDocument == target
      check = (prop) =>
        @state[prop] = null if @state[prop] and isDead(@state[prop])

      check('lastFocusedTextInput')
      @state.scrollableElements.reject(isDead)
      # `markerElements` and `inputs` could theoretically need to be filtered
      # too at this point. YAGNI until an issue arises from it.

  options: (prefs) -> messageManager.get('options', {prefs})

  enterMode: (@mode, args...) ->
    messageManager.send('vimMethod', {
      method: 'enterMode'
      args: [@mode, args...]
    })

  onInput: (event) ->
    focusType = utils.getFocusType(event.originalTarget)
    suppress = messageManager.get('consumeKeyEvent', {focusType})
    return suppress

  notify: (args...) ->
    messageManager.send('vimMethod', {method: 'notify', args})

  markPageInteraction: -> @state.hasInteraction = true

module.exports = VimFrame
