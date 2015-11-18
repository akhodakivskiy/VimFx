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
    @numFocusToSuppress = 0

  listen: utils.listen.bind(null, FRAME_SCRIPT_ENVIRONMENT)
  listenOnce: utils.listenOnce.bind(null, FRAME_SCRIPT_ENVIRONMENT)

  addListeners: ->
    # If the page already was loaded when VimFx was initialized, send the
    # 'DOMWindowCreated' message straight away.
    if @vim.content.document.readyState in ['interactive', 'complete']
      messageManager.send('DOMWindowCreated')
    else
      @listen('DOMWindowCreated', (event) ->
        messageManager.send('DOMWindowCreated')
      )

    @listen('readystatechange', (event) =>
      target = event.originalTarget

      # If the topmost document starts loading, it means that we have navigated
      # to a new page or refreshed the page.
      if target == @vim.content.document and target.readyState == 'interactive'
        messageManager.send('locationChange', @vim.content.location.href)
    )

    @listen('pagehide', (event) =>
      target = event.originalTarget

      if target == @vim.content.document
        @vim.resetState()
      else
        # If the target isn’t the topmost document, it means that a frame has
        # changed: It could have been removed or its `src` attribute could have
        # been changed. Any scrollable elements in the frame (or its sub-frames)
        # then need to be filtered out.
        @vim.state.scrollableElements
          .reject(utils.windowContainsDeep.bind(null, target.defaultView))
    )

    @listen('click', (event) =>
      if @vim.mode == 'hints' and event.isTrusted
        messageManager.send('enterMode', {mode: 'normal'})
    )

    @listen('overflow', (event) =>
      target = event.originalTarget
      return unless computedStyle = @vim.content.getComputedStyle(target)
      unless computedStyle.getPropertyValue('overflow-y') == 'hidden' and
             computedStyle.getPropertyValue('overflow-x') == 'hidden'
        @vim.state.scrollableElements.add(target)
    )

    @listen('underflow', (event) =>
      target = event.originalTarget
      @vim.state.scrollableElements.delete(target)
    )

    @listen('keydown', (event) =>
      suppress = @vim.onInput(event)

      # This also suppresses the 'keypress' and 'keyup' events. (Yes, in frame
      # scripts, suppressing the 'keydown' events does seem to even suppress
      # the 'keyup' event!)
      utils.suppressEvent(event) if suppress

      # From this line on, the rest of the code in `addListeners` is more or
      # less devoted to autofocus prevention. When enabled, focus events that
      # occur before the user has interacted with page are prevented.
      #
      # If this keydown event wasn’t suppressed (`not suppress`), it’s an
      # obvious interaction with the page. If it _was_ suppressed, though, it’s
      # an interaction depending on the command triggered; if it calls
      # `vim.markPageInteraction()` or not.
      @vim.markPageInteraction() unless suppress
    )

    @listen('keydown', ((event) ->
      suppress = messageManager.get('lateKeydown', {
        defaultPrevented: event.defaultPrevented
      })
      utils.suppressEvent(event) if suppress
    ), false)

    # Clicks are always counted as page interaction. Listen for 'mousedown'
    # instead of 'click' to mark the interaction as soon as possible.
    @listen('mousedown', @vim.markPageInteraction.bind(@vim))

    messageManager.listen('browserRefocus', =>
      # Suppress the next two focus events (for `document` and `window`; see
      # `blurActiveBrowserElement`).
      @numFocusToSuppress = 2
    )

    @listen('focus', (event) =>
      target = event.originalTarget

      if @numFocusToSuppress > 0
        utils.suppressEvent(event)
        @numFocusToSuppress--
        return

      # Reset `hasInteraction` when (re-)selecting a tab, or coming back from
      # another window, in order to prevent the common “automatically re-focus
      # when switching back to the tab” behaviour many sites have, unless a text
      # input _should_ be re-focused when coming back to the tab (see the 'blur'
      # event below).
      if target == @vim.content.document
        if @vim.state.shouldRefocus
          @vim.state.hasInteraction = true
          @vim.state.shouldRefocus = false
        else
          @vim.state.hasInteraction = false
        return

      # Save the last focused text input regardless of whether that input might
      # be blurred because of autofocus prevention.
      if utils.isTextInputElement(target)
        @vim.state.lastFocusedTextInput = target

      focusManager = Cc['@mozilla.org/focus-manager;1']
        .getService(Ci.nsIFocusManager)

      # When moving a tab to another window, there is a short period of time
      # when there’s no listener for this call.
      return unless options = @vim.options(
        ['prevent_autofocus', 'prevent_autofocus_modes']
      )

      # Blur the focus target, if autofocus prevention is enabled…
      if options.prevent_autofocus and
          @vim.mode in options.prevent_autofocus_modes and
          # …and the user has interacted with the page…
          not @vim.state.hasInteraction and
          # …and the event is programmatic (not caused by clicks or keypresses)…
          focusManager.getLastFocusMethod(null) == 0 and
          # …and the target may steal most keystrokes.
          (utils.isTypingElement(target) or utils.isContentEditable(target))
        # Some sites (such as icloud.com) re-focuses inputs if they are blurred,
        # causing an infinite loop of autofocus prevention and re-focusing.
        # Therefore, blur events that happen just after an autofocus prevention
        # are suppressed.
        @listenOnce('blur', utils.suppressEvent)
        target.blur()
    )

    @listen('blur', (event) =>
      target = event.originalTarget

      # If a text input is blurred immediately before the document loses focus,
      # it most likely means that the user switched tab, for example by pressing
      # `<c-tab>`, or switched to another window, while the text input was
      # focused. In this case, when switching back to that tab, the text input
      # will, and should, be re-focused (because it was focused when you left
      # the tab). This case is kept track of so that the autofocus prevention
      # does not catch it.
      if utils.isTypingElement(target) or utils.isContentEditable(target)
        utils.nextTick(@vim.content, =>
          @vim.state.shouldRefocus = not @vim.content.document.hasFocus()
        )
    )

module.exports = FrameEventManager
