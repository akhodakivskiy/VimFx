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

# This file is the equivalent to events.coffee, but for frame scripts.

notation = require('vim-like-key-notation')
commands = require('./commands-frame')
messageManager = require('./message-manager')
utils = require('./utils')

nsIFocusManager = Cc['@mozilla.org/focus-manager;1']
  .getService(Ci.nsIFocusManager)

XULDocument = Ci.nsIDOMXULDocument

class FrameEventManager
  constructor: (@vim) ->
    @numFocusToSuppress = 0
    @keepInputs = false
    @currentUrl = false

  listen: utils.listen.bind(null, FRAME_SCRIPT_ENVIRONMENT)
  listenOnce: utils.listenOnce.bind(null, FRAME_SCRIPT_ENVIRONMENT)

  addListeners: ->
    # If the page already was loaded when VimFx was initialized, send the
    # 'frameCanReceiveEvents' message straight away.
    if @vim.content.document.readyState == 'complete'
      messageManager.send('frameCanReceiveEvents', true)

    @listen('readystatechange', (event) =>
      target = event.originalTarget
      topDocument = @vim.content.document
      [oldUrl, @currentUrl] = [@currentUrl, @vim.content.location.href]

      switch target.readyState
        when 'interactive'
          if target == topDocument or
             # When loading the editor on codepen.io, a frame gets
             # 'readystatechange' → 'interactive' quite a bit before the
             # toplevel document does. Checking for this case lets us send
             # 'locationChange' earlier, allowing to enter Ignore mode earlier,
             # for example. Be careful not to trigger a 'locationChange' for
             # frames loading _after_ the toplevel document, though.
             (topDocument.readyState == 'loading' and oldUrl == null)
            messageManager.send('locationChange', @currentUrl)

        when 'complete'
          if target == topDocument
            messageManager.send('frameCanReceiveEvents', true)
    )

    @listen('pageshow', (event) =>
      [oldUrl, @currentUrl] = [@currentUrl, @vim.content.location.href]

      # When navigating the history, `event.persisted` is `true` (meaning that
      # the page loaded from cache) and 'readystatechange' won’t be fired, so
      # send a 'locationChange' message to make sure that the blacklist is
      # applied etc. The reason we don’t simply _always_ do this on the
      # 'pageshow' event, is because it usually fires too late. However, it also
      # fires after having moved a tab to another window. In that case it is
      # _not_ a location change; the blacklist should not be applied.
      if event.persisted
        url = @vim.content.location.href
        messageManager.send('cachedPageshow', null, (movedToNewTab) =>
          if not movedToNewTab and oldUrl != @currentUrl
            messageManager.send('locationChange', @currentUrl)
        )
    )

    @listen('pagehide', (event) =>
      target = event.originalTarget
      @currentUrl = null

      if target == @vim.content.document
        messageManager.send('frameCanReceiveEvents', false)

      # If the target isn’t the topmost document, it means that a frame has
      # changed: It could have been removed or its `src` attribute could have
      # been changed. If the frame contains other frames, 'pagehide' events have
      # already been fired for them.
      @vim.resetState(target)
    )

    messageManager.listen('getMarkableElementsMovements', (data, callback) =>
      diffs = @vim.state.markerElements.map(({element, originalRect}) ->
        newRect = element.getBoundingClientRect()
        return {
          dx: newRect.left - originalRect.left
          dy: newRect.top  - originalRect.top
        }
      )
      callback(diffs)
    )

    @listen('overflow', (event) =>
      target = event.originalTarget
      @vim.state.scrollableElements.addChecked(target)
    )

    @listen('underflow', (event) =>
      target = event.originalTarget
      @vim.state.scrollableElements.deleteChecked(target)
    )

    @listen('keydown', (event) =>
      @keepInputs = false
    )

    @listen('keydown', ((event) =>
      suppress = messageManager.get('lateKeydown', {
        defaultPrevented: event.defaultPrevented
      })

      if @vim.state.inputs and @vim.mode == 'normal' and not suppress and
         not event.defaultPrevented
        # There is no need to take `ignore_keyboard_layout` and `translations`
        # into account here, since we want to override the _native_ `<tab>`
        # behavior. Then, `event.key` is the way to go. (Unless the prefs are
        # customized. YAGNI until requested.)
        keyStr = notation.stringify(event)
        options = @vim.options(['focus_previous_key', 'focus_next_key'])
        direction = switch keyStr
          when ''
            null
          when options.focus_previous_key
            -1
          when options.focus_next_key
            +1
          else
            null
        if direction?
          suppress = commands.move_focus({@vim, direction})
          @keepInputs = true

      utils.suppressEvent(event) if suppress
    ), false)

    @listen('mousedown', (event) =>
      # Allow clicking on another text input without exiting “gi mode”. Listen
      # for 'mousedown' instead of 'click', because only the former runs before
      # the 'blur' event. Also, `event.originalTarget` does _not_ work here.
      @keepInputs = (@vim.state.inputs and event.target in @vim.state.inputs)

      # Clicks are always counted as page interaction. Listen for 'mousedown'
      # instead of 'click' to mark the interaction as soon as possible.
      @vim.markPageInteraction()
    )

    messageManager.listen('browserRefocus', =>
      # Suppress the next two focus events (for `document` and `window`; see
      # `blurActiveBrowserElement`).
      @numFocusToSuppress = 2
    )

    sendFocusType = =>
      return unless activeElement = utils.getActiveElement(@vim.content)
      focusType = utils.getFocusType(activeElement)
      messageManager.send('focusType', focusType)

    @listen('focus', (event) =>
      target = event.originalTarget

      if @numFocusToSuppress > 0
        utils.suppressEvent(event)
        @numFocusToSuppress -= 1
        return

      @vim.state.explicitBodyFocus = (target == @vim.content.document.body)

      sendFocusType()

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
        @vim.state.hasFocusedTextInput = true

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
         nsIFocusManager.getLastFocusMethod(null) == 0 and
         # …and the target may steal most keystrokes…
         utils.isTypingElement(target) and
         # …and the page isn’t a Firefox internal page (like `about:config`).
         @vim.content.document not instanceof XULDocument
        # Some sites (such as icloud.com) re-focuses inputs if they are blurred,
        # causing an infinite loop of autofocus prevention and re-focusing.
        # Therefore, blur events that happen just after an autofocus prevention
        # are suppressed.
        @listenOnce('blur', utils.suppressEvent)
        target.blur()
        @vim.state.hasFocusedTextInput = false
    )

    @listen('blur', (event) =>
      target = event.originalTarget

      sendFocusType()

      # If a text input is blurred immediately before the document loses focus,
      # it most likely means that the user switched tab, for example by pressing
      # `<c-tab>`, or switched to another window, while the text input was
      # focused. In this case, when switching back to that tab, the text input
      # will, and should, be re-focused (because it was focused when you left
      # the tab). This case is kept track of so that the autofocus prevention
      # does not catch it.
      if utils.isTypingElement(target)
        utils.nextTick(@vim.content, =>
          @vim.state.shouldRefocus = not @vim.content.document.hasFocus()

          # “gi mode” ends when blurring a text input, unless `<tab>` was just
          # pressed.
          unless @vim.state.shouldRefocus or @keepInputs
            commands.clear_inputs({@vim})
        )
    )

module.exports = FrameEventManager
