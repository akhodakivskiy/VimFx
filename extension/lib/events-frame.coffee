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

# This file is the equivalent to events.coffee, but for frame scripts.

messageManager = require('./message-manager')
utils          = require('./utils')

class FrameEventManager
  constructor: (@vim) ->

  listen: utils.listen.bind(null, FRAME_SCRIPT_ENVIRONMENT)
  listenOnce: utils.listenOnce.bind(null, FRAME_SCRIPT_ENVIRONMENT)

  addListeners: ->
    @listen('DOMWindowCreated', @vim.resetState.bind(@vim))

    @listen('keydown', (event) =>
      suppress = @vim.onInput(event)
      # If the event wasn’t suppressed, it’s on obvious interaction with the
      # page. If it _was_ suppressed, though, it’s an interaction depending on
      # the command triggered; if it calls `vim.markPageInteraction()` or not.
      @vim.markPageInteraction() unless suppress
    )

    @listen('overflow', (event) =>
      return unless computedStyle = @vim.content.getComputedStyle(event.target)
      return if computedStyle.getPropertyValue('overflow') == 'hidden'
      @vim.state.scrollableElements.add(event.target)
    )

    @listen('underflow', (event) =>
      @vim.state.scrollableElements.delete(event.target)
    )

    @listen('focus', (event) =>
      target = event.originalTarget

      options = @vim.options(['prevent_autofocus', 'prevent_autofocus_modes'])

      if utils.isTextInputElement(target)
        @vim.state.lastFocusedTextInput = target

      # Autofocus prevention. Strictly speaking, autofocus may only happen
      # during page load, which means that we should only prevent focus events
      # during page load. However, it is very difficult to reliably determine
      # when the page load ends. Moreover, a page may load very slowly. Then it
      # is likely that the user tries to focus something before the page has
      # loaded fully. Therefore any and all focus events that fire before the
      # user has interacted with the page (clicked or pressed a key) are blurred
      # (regardless of whether the page is loaded or not).
      focusManager = Cc['@mozilla.org/focus-manager;1']
        .getService(Ci.nsIFocusManager)
      if options.prevent_autofocus and not @vim.state.hasInteraction and
          @vim.mode in options.prevent_autofocus_modes and
          # Only blur programmatic events (not caused by clicks or keypresses).
          focusManager.getLastFocusMethod(null) == 0 and
          # Only blur elements that may steal most keystrokes.
          (utils.isTextInputElement(target) or utils.isContentEditable(target))
        # Some sites (such as icloud.com) re-focuses inputs if they are blurred,
        # causing an infinite loop of autofocus prevention and re-focusing.
        # Therefore we suppress blur events that happen just after an autofocus
        # prevention.
        @listenOnce('blur', utils.suppressEvent)
        target.blur()
    )

    @listen('mousedown', (event) => @vim.markPageInteraction())

    @listen('click', (event) =>
      if @vim.mode == 'hints' and event.isTrusted
        messageManager.send('enterMode', {mode: 'normal'})
    )

module.exports = FrameEventManager
