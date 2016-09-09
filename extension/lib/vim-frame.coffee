###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
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
# keeps track of web page state. `VimFrame` is not part of the config file API.

messageManager = require('./message-manager')
ScrollableElements = require('./scrollable-elements')
utils = require('./utils')

class VimFrame
  constructor: (@content) ->
    @mode = 'normal'
    @hintMatcher = null

    @resetState()

    messageManager.listen('modeChange', ({mode}) =>
      @mode = mode
    )

    messageManager.listen(
      'markPageInteraction', @markPageInteraction.bind(this)
    )

    messageManager.listen('clearHover', @clearHover.bind(this))

  # If the target is the topmost document, reset everything. Otherwise filter
  # out elements belonging to the target frame. On some sites, such as Gmail,
  # some elements might be dead at this point.
  resetState: (target = @content.document) ->
    if target == @content.document
      @state = {
        hasInteraction: false
        shouldRefocus: false
        marks: {}
        explicitBodyFocus: false
        hasFocusedTextInput: false
        lastFocusedTextInput: null
        lastHover: {
          element: null
          browserOffset: {x: 0, y: 0}
        }
        scrollableElements: new ScrollableElements(@content)
        markerElements: []
        inputs: null
      }

    else
      isDead = (element) ->
        return Cu.isDeadWrapper(element) or element.ownerDocument == target
      check = (obj, prop) ->
        obj[prop] = null if obj[prop] and isDead(obj[prop])

      check(@state, 'lastFocusedTextInput')
      check(@state.lastHover, 'element')
      @state.scrollableElements.reject(isDead)
      # `markerElements` and `inputs` could theoretically need to be filtered
      # too at this point. YAGNI until an issue arises from it.

  options: (prefs) -> messageManager.get('options', {prefs})

  _enterMode: (@mode, args...) ->
    messageManager.send('vimMethod', {
      method: '_enterMode'
      args: [@mode, args...]
    })

  notify: (args...) ->
    messageManager.send('vimMethod', {method: 'notify', args})

  hideNotification: ->
    messageManager.send('vimMethod', {method: 'hideNotification'})

  markPageInteraction: (value = true) -> @state.hasInteraction = value

  setHover: (element, browserOffset) ->
    utils.setHover(element, true)
    utils.simulateMouseEvents(element, 'hover-start', browserOffset)
    @state.lastHover.element = element
    @state.lastHover.browserOffset = browserOffset

  clearHover: ->
    if @state.lastHover.element
      {element, browserOffset} = @state.lastHover
      utils.setHover(element, false)
      utils.simulateMouseEvents(element, 'hover-end', browserOffset)
    @state.lastHover.element = null

module.exports = VimFrame
