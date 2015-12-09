###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
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

# This file sets up all event listeners needed to power VimFx: To know when to
# launch commands and to provide state to them. Events in web page content are
# listened for in events-frame.coffee.

button         = require('./button')
messageManager = require('./message-manager')
utils          = require('./utils')

HELD_MODIFIERS_ATTRIBUTE = 'vimfx-held-modifiers'

class UIEventManager
  constructor: (@vimfx, @window) ->
    @listen = utils.listen.bind(null, @window)
    @listenOnce = utils.listenOnce.bind(null, @window)

    # This flag controls whether to suppress the various key events or not.
    @suppress = false

    # If a matched shortcut has the `<late>` special key, this flag is set to
    # `true`.
    @late = false

    # When a menu or panel is shown VimFx should temporarily stop processing
    # keyboard input, allowing accesskeys to be used.
    @popupPassthrough = false

    @enteredKeys = new EnteredKeysManager(@window)

  addListeners: ->
    checkPassthrough = (value, event) =>
      target = event.originalTarget
      if target.nodeName in ['menupopup', 'panel']
        @popupPassthrough = value

    @listen('popupshown',  checkPassthrough.bind(null, true))
    @listen('popuphidden', checkPassthrough.bind(null, false))

    @listen('keydown', (event) =>
      # No matter what, always reset the `@suppress` flag, so we don't
      # suppress more than intended.
      @suppress = false

      # Reset the `@late` flag, telling any late listeners for the previous
      # event not to run.
      @late = false

      if @popupPassthrough
        # The `@popupPassthrough` flag is set a bit unreliably. Sometimes it
        # can be stuck as `true` even though no popup is shown, effectively
        # disabling the extension. Therefore we check if there actually _are_
        # any open popups before stopping processing keyboard input. This is
        # only done when popups (might) be open (not on every keystroke) of
        # performance reasons.
        #
        # The autocomplete popup in text inputs (for example) is technically a
        # panel, but it does not respond to key presses. Therefore
        # `[ignorekeys="true"]` is excluded.
        #
        # coffeelint: disable=max_line_length
        # <https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XUL/PopupGuide/PopupKeys#Ignoring_Keys>
        # coffeelint: enable=max_line_length
        popups = @window.document.querySelectorAll(
          ':-moz-any(menupopup, panel):not([ignorekeys="true"])'
        )
        for popup in popups
          return if popup.state == 'open'
        @popupPassthrough = false # No popup was actually open.

      return unless vim = @vimfx.getCurrentVim(@window)

      if vim.isUIEvent(event)
        focusType = utils.getFocusType(event.originalTarget)
        @consumeKeyEvent(vim, event, focusType, event)
        # This also suppresses the 'keypress' event.
        utils.suppressEvent(event) if @suppress
      else
        vim._listenOnce('consumeKeyEvent', ({focusType}) =>
          @consumeKeyEvent(vim, event, focusType)
          return @suppress
        )
    )

    @listen('keyup', (event) =>
      utils.suppressEvent(event) if @suppress
      @setHeldModifiers(event, {filterCurrentOnly: true})
    )

    handleFocusRelatedEvent = (options, event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)

      findBar = @window.gBrowser.getFindBar()
      if target == findBar._findField.mInputField
        vim.enterMode(options.mode)

      if vim.isUIEvent(event)
        focusType = utils.getFocusType(utils.getActiveElement(@window))
        @vimfx.emit('focusTypeChange', {vim, focusType})

    @listen('focus', handleFocusRelatedEvent.bind(null, {mode: 'find'}))
    @listen('blur',  handleFocusRelatedEvent.bind(null, {mode: 'normal'}))

    @listen('click', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)

      # If the user clicks the reload button or a link when in hints mode, we’re
      # going to end up in hints mode without any markers. Or if the user clicks
      # a text input, then that input will be focused, but you can’t type in it
      # (instead markers will be matched). So if the user clicks anything in
      # hints mode it’s better to leave it.
      if vim.mode == 'hints' and vim.isUIEvent(event) and
         # Exclude the VimFx button, though, since clicking it returns to normal
         # mode. Otherwise we’d first return to normal mode and then the button
         # would open the help dialog.
         target != button.getButton(@window)
        vim.enterMode('normal')
    )

    @listen('overflow', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)
      vim._state.scrollableElements.addChecked(target)
    )

    @listen('underflow', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)
      vim._state.scrollableElements.deleteChecked(target)
    )

    @listen('TabSelect', (event) =>
      @vimfx.emit('TabSelect', event)

      return unless vim = @vimfx.getCurrentVim(@window)
      vim.hideNotification()
    )

    @listen('TabClose', (event) =>
      browser = @window.gBrowser.getBrowserForTab(event.originalTarget)
      return unless vim = @vimfx.vims.get(browser)
      # Note: `lastClosedVim` must be stored so that any window can access it.
      @vimfx.lastClosedVim = vim
    )

    messageManager.listen('cachedPageshow', ((data, args) =>
      {target: browser, callback} = args
      exit = (movedToNewTab) ->
        messageManager.send(callback, movedToNewTab) if callback

      [oldVim, @vimfx.lastClosedVim] = [@vimfx.lastClosedVim, null]
      unless oldVim
        exit(false)
        return

      if @vimfx.vims.has(browser)
        vim = @vimfx.vims.get(browser)
        if vim._messageManager == vim.browser.messageManager
          exit(false)
          return

      # If we get here, it means that we’ve detected a tab dragged from one
      # window to another. If so, the `vim` object from the last closed tab (the
      # moved tab) should be re-used. See the commit message for commit bb70257d
      # for more details.
      oldVim._setBrowser(browser)
      @vimfx.vims.set(browser, oldVim)
      @vimfx.emit('modeChange', oldVim)
      exit(true)
    ), @window.messageManager)

  consumeKeyEvent: (vim, event, focusType, uiEvent = false) ->
    match = vim._consumeKeyEvent(event, focusType)

    if match
      if @vimfx.options.notify_entered_keys
        if match.type in ['none', 'full'] or match.focus != null
          @enteredKeys.clear(vim)
        else
          @enteredKeys.push(vim, match.keyStr, @vimfx.options.timeout)
      else
        vim.hideNotification()

      if match.specialKeys['<late>']
        @suppress = false
        @consumeLateKeydown(vim, event, match, uiEvent)
      else
        @suppress = vim._onInput(match, uiEvent)
    else
      @suppress = null
    @setHeldModifiers(event)

  consumeLateKeydown: (vim, event, match, uiEvent) ->
    @late = true

    # The passed in `event` is the regular non-late browser UI keydown event.
    # It is only used to set held keys. This is easier than sending an event
    # subset from frame scripts.
    listener = ({defaultPrevented}) =>
      # `@late` is reset on every keydown. If it is no longer `true`, it means
      # that the page called `event.stopPropagation()`, which prevented this
      # listener from running for that event.
      return unless @late
      @suppress =
        if defaultPrevented
          false
        else
          vim._onInput(match, uiEvent)
      @setHeldModifiers(event)
      return @suppress

    if uiEvent
      @listenOnce('keydown', ((lateEvent) =>
        listener(lateEvent)
        if @suppress
          utils.suppressEvent(lateEvent)
          @listenOnce('keyup', utils.suppressEvent, false)
      ), false)
    else
      vim._listenOnce('lateKeydown', listener)

  setHeldModifiers: (event, {filterCurrentOnly = false} = {}) ->
    mainWindow = @window.document.documentElement
    modifiers =
      if filterCurrentOnly
        mainWindow.getAttribute(HELD_MODIFIERS_ATTRIBUTE)
      else
        if @suppress == null then 'alt ctrl meta shift' else ''
    isHeld = (modifier) -> event["#{modifier}Key"]
    mainWindow.setAttribute(HELD_MODIFIERS_ATTRIBUTE,
                            modifiers.split(' ').filter(isHeld).join(' '))

class EnteredKeysManager
  constructor: (@window) ->
    @keys = []
    @timeout = null

  clear: (notifier) ->
    @keys = []
    @clearTimeout()
    notifier.hideNotification()

  push: (notifier, keyStr, duration) ->
    @keys.push(keyStr)
    @clearTimeout()
    notifier.notify(@keys.join(''))
    @timeout = @window.setTimeout(@clear.bind(this, notifier), duration)

  clearTimeout: ->
    @window.clearTimeout(@timeout) if @timeout?
    @timeout = null

module.exports = UIEventManager
