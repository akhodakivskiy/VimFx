# This file is the equivalent to events.coffee, but for frame scripts.

notation = require('vim-like-key-notation')
commands = require('./commands-frame')
messageManager = require('./message-manager')
prefs = require('./prefs')
utils = require('./utils')

nsIFocusManager = Cc['@mozilla.org/focus-manager;1']
  .getService(Ci.nsIFocusManager)

class FrameEventManager
  constructor: (@vim) ->
    @numFocusToSuppress = 0
    @keepInputs = false
    @currentUrl = false
    @disconnectActiveElementObserver = null

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
             # frames loading _after_ the toplevel document, though. Finally,
             # checking for 'uninitialized' is needed to be able to blacklist
             # some XUL pages.
             (topDocument.readyState in ['loading', 'uninitialized'] and
              oldUrl == null)
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
        @vim._enterMode('normal') if @vim.mode == 'hints'

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

    messageManager.listen('highlightMarkableElements', (data) =>
      {elements, strings} = data
      utils.clearSelectionDeep(@vim.content)
      for {elementIndex, selectAll} in elements
        {element} = @vim.state.markerElements[elementIndex]
        if selectAll
          utils.selectElement(element)
        else
          for string in strings
            utils.selectAllSubstringMatches(
              element, string, {caseSensitive: false}
            )
      return
    )

    @listen('overflow', (event) =>
      # XXX(fission): this eventually calls utils::containsDeep(), which if the
      # element that caused the event sits in an out-of-process iframe, might
      # cause a SecurityError. However, as of Nightly 78, events originating
      # from such frames are not raised.
      target = event.originalTarget
      @vim.state.scrollableElements.addChecked(target)
    )

    @listen('underflow', (event) =>
      target = event.originalTarget
      @vim.state.scrollableElements.deleteChecked(target)
    )

    @listen('submit', ((event) ->
      return if event.defaultPrevented
      target = event.originalTarget
      activeElement = utils.getActiveElement(target.ownerDocument.defaultView)
      if activeElement?.form == target and utils.isTypingElement(activeElement)
        activeElement.blur()
    ), false)

    @listen('keydown', (event) =>
      @keepInputs = false
    )

    @listen('keydown', ((event) =>
      suppress = false

      # This message _has_ to be synchronous so we can suppress the event if
      # needed. To avoid sending a synchronous message on _every_ keydown, this
      # hack of toggling a pref when a `<late>` shortcut is encountered is used.
      if prefs.get('late')
        suppress = messageManager.get('lateKeydown', {
          defaultPrevented: event.defaultPrevented
        })

      if @vim.state.inputs and @vim.mode == 'normal' and not suppress and
         not event.defaultPrevented
        # There is no need to take `ignore_keyboard_layout` and `translations`
        # into account here, since we want to override the _native_ `<tab>`
        # behavior. Then, `event.key` is the way to go. (Unless the prefs are
        # customized. YAGNI until requested.) Also, since 'keydown' is fired so
        # often the options are read directly from the prefs system for
        # performance. That means you can’t override them with
        # `vimfx.addOptionOverrides`. YAGNI until requested.
        keyStr = notation.stringify(event)
        direction = switch keyStr
          when ''
            null
          when prefs.get('focus_previous_key')
            -1
          when prefs.get('focus_next_key')
            +1
          else
            null
        if direction?
          suppress = commands.move_focus({@vim, direction})
          @keepInputs = true

      if suppress
        utils.suppressEvent(event)
        @listenOnce('keyup', utils.suppressEvent, false)
    ), false)

    @listen('mousedown', (event) =>
      # Allow clicking on another text input without exiting “gi mode”. Listen
      # for 'mousedown' instead of 'click', because only the former runs before
      # the 'blur' event. Also, `event.originalTarget` does _not_ work here.
      @keepInputs = (@vim.state.inputs and event.target in @vim.state.inputs)

      # Clicks are always counted as page interaction. Listen for 'mousedown'
      # instead of 'click' to mark the interaction as soon as possible.
      @vim.markPageInteraction()

      @vim.hideNotification()
    )

    messageManager.listen('browserRefocus', =>
      # Suppress the next two focus events (for `document` and `window`; see
      # `blurActiveBrowserElement`).
      @numFocusToSuppress = 2
    )

    @listen('focus', (event) =>
      target = event.originalTarget

      if @numFocusToSuppress > 0
        utils.suppressEvent(event)
        @numFocusToSuppress -= 1
        return

      @vim.state.explicitBodyFocus = (target == @vim.content.document.body)

      @sendFocusType()

      # Reset `hasInteraction` when (re-)selecting a tab, or coming back from
      # another window, in order to prevent the common “automatically re-focus
      # when switching back to the tab” behaviour many sites have, unless a text
      # input _should_ be re-focused when coming back to the tab (see the 'blur'
      # event below).
      if target == @vim.content.document
        if @vim.state.shouldRefocus
          @vim.markPageInteraction(true)
          # When Firefox is re-focused after using a keyboard shortcut to switch
          # keyboard layout in GNOME, _two_ focus events for the document are
          # triggered, about 50ms apart. Therefore, reset the `shouldRefocus`
          # after a timeout.
          @vim.content.setTimeout((=>
            @vim.state.shouldRefocus = false
          ), prefs.get('refocus_timeout'))
        else
          @vim.markPageInteraction(false)
        return

      if utils.isTextInputElement(target)
        # Save the last focused text input regardless of whether that input
        # might be blurred because of autofocus prevention.
        @vim.state.lastFocusedTextInput = target
        @vim.state.hasFocusedTextInput = true

        if @vim.mode == 'caret' and not utils.isContentEditable(target)
          @vim._enterMode('normal')

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
         # …and the target may steal most keystrokes
         utils.isTypingElement(target)
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

      if target == @vim.state.lastHover.element and
         # Facebook “like” button exception. The “emoji picker” immediately
         # closes otherwise.
         not target.classList?.contains('UFILikeLink')
        @vim.clearHover()

      @vim.content.setTimeout((=>
        @sendFocusType()
      ), prefs.get('blur_timeout'))

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

    @listen('popstate', =>
      @vim.markPageInteraction(false)
    )

    messageManager.listen('checkFocusType', @sendFocusType.bind(this))

  sendFocusType: ({ignore = []} = {}) ->
    return unless utils and activeElement = utils.getActiveElement(@vim.content)
    focusType = utils.getFocusType(activeElement)
    messageManager.send('focusType', focusType) unless focusType in ignore

    # If a text input is removed from the DOM while it is focused, no 'focus'
    # or 'blur' events will be fired, making VimFx think that the text input is
    # still focused. Therefore we add a temporary observer for the currently
    # focused element and re-send the focusType if it gets removed.
    @disconnectActiveElementObserver?()
    @disconnectActiveElementObserver =
      if focusType == 'none'
        null
      else
        utils.onRemoved(activeElement, @sendFocusType.bind(this))

module.exports = FrameEventManager
