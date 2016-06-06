###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
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

# This file sets up all event listeners needed to power VimFx: To know when to
# launch commands and to provide state to them. Events in web page content are
# listened for in events-frame.coffee.

button = require('./button')
messageManager = require('./message-manager')
prefs = require('./prefs')
utils = require('./utils')

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
      if target.localName in ['menupopup', 'panel'] and
         # Don’t set `@popupPassthrough` to `false` if there actually are popups
         # open. This is the case when a sub-menu closes.
         (value or not @anyPopupsOpen())
        @popupPassthrough = value

    @listen('popupshown',  checkPassthrough.bind(null, true))
    @listen('popuphidden', checkPassthrough.bind(null, false))

    @listen('keydown', (event) =>
      # No matter what, always reset the `@suppress` flag, so we don't
      # suppress more than intended.
      @suppress = false

      # Reset the `@late` flag, telling any late listeners for the previous
      # event not to run. Also reset the `late` pref, telling frame scripts not
      # to do synchronous message passing on every keydown.
      @late = false
      prefs.set('late', false)

      if @popupPassthrough
        # The `@popupPassthrough` flag is set a bit unreliably. Sometimes it
        # can be stuck as `true` even though no popup is shown, effectively
        # disabling the extension. Therefore we check if there actually _are_
        # any open popups before stopping processing keyboard input. This is
        # only done when popups (might) be open (not on every keystroke) for
        # performance reasons.
        return if @anyPopupsOpen()
        @popupPassthrough = false # No popup was actually open.

      return unless vim = @vimfx.getCurrentVim(@window)

      @consumeKeyEvent(vim, event)
      if @suppress
        utils.suppressEvent(event) # This also suppresses the 'keypress' event.
      else
        # If this keydown event wasn’t suppressed, it’s an obvious interaction
        # with the page. If it _was_ suppressed, though, it’s an interaction
        # depending on the command triggered; if _it_ calls
        # `vim.markPageInteraction()` or not.
        vim.markPageInteraction() if vim.isUIEvent(event)
    )

    @listen('keyup', (event) =>
      utils.suppressEvent(event) if @suppress
      @setHeldModifiers(event, {filterCurrentOnly: true})
    )

    @listen('focus', => @setFocusType())
    @listen('blur', =>
      @window.setTimeout((=>
        @setFocusType()
      ), @vimfx.options.blur_timeout)
    )

    @listen('click', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)

      # In multi-process, clicks simulated by VimFx cannot be caught here. In
      # non-multi-process, they unfortunately can. This hack should be
      # sufficient for that case until non-multi-process is removed from
      # Firefox.
      isVimFxGeneratedEvent = (
        event.layerX == 0 and event.layerY == 0 and
        event.movementX == 0 and event.movementY == 0
      )

      # If the user clicks the reload button or a link when in hints mode, we’re
      # going to end up in hints mode without any markers. Or if the user clicks
      # a text input, then that input will be focused, but you can’t type in it
      # (instead markers will be matched). So if the user clicks anything in
      # hints mode it’s better to leave it.
      if vim.mode == 'hints' and not isVimFxGeneratedEvent and
         # Exclude the VimFx button, though, since clicking it returns to normal
         # mode. Otherwise we’d first return to normal mode and then the button
         # would open the help dialog.
         target != button.getButton(@window)
        vim.enterMode('normal')

      vim._send('clearHover') unless isVimFxGeneratedEvent
    )

    @listen('overflow', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)
      if vim._isUIElement(target)
        vim._state.scrollableElements.addChecked(target)
    )

    @listen('underflow', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)
      if vim._isUIElement(target)
        vim._state.scrollableElements.deleteChecked(target)
    )

    @listen('TabSelect', (event) =>
      target = event.originalTarget
      target.setAttribute('VimFx-visited', 'true')
      @vimfx.emit('TabSelect', {event})

      return unless vim = @vimfx.getCurrentVim(@window)
      vim.hideNotification()
      @vimfx.emit('focusTypeChange', {vim})
    )

    @listen('TabClose', (event) =>
      browser = @window.gBrowser.getBrowserForTab(event.originalTarget)
      return unless vim = @vimfx.vims.get(browser)
      # Note: `lastClosedVim` must be stored so that any window can access it.
      @vimfx.lastClosedVim = vim
    )

    messageManager.listen('cachedPageshow', ((data, callback, browser) =>
      [oldVim, @vimfx.lastClosedVim] = [@vimfx.lastClosedVim, null]
      unless oldVim
        callback(false)
        return

      if @vimfx.vims.has(browser)
        vim = @vimfx.vims.get(browser)
        if vim._messageManager == vim.browser.messageManager
          callback(false)
          return

      # If we get here, it means that we’ve detected a tab dragged from one
      # window to another. If so, the `vim` object from the last closed tab (the
      # moved tab) should be re-used. See the commit message for commit bb70257d
      # for more details.
      oldVim._setBrowser(browser)
      @vimfx.vims.set(browser, oldVim)
      @vimfx.emit('modeChange', {vim: oldVim})
      callback(true)
    ), {messageManager: @window.messageManager})

  setFocusType: ->
    return unless vim = @vimfx.getCurrentVim(@window)

    activeElement = utils.getActiveElement(@window)

    if activeElement == @window.gBrowser.selectedBrowser
      vim._send('checkFocusType')
      return

    focusType = utils.getFocusType(activeElement)
    vim._setFocusType(focusType)

    if focusType == 'editable' and vim.mode == 'caret'
      vim.enterMode('normal')

  consumeKeyEvent: (vim, event) ->
    match = vim._consumeKeyEvent(event)

    if match
      if @vimfx.options.notify_entered_keys and vim.mode != 'ignore'
        if match.type in ['none', 'full'] or match.likelyConflict
          @enteredKeys.clear(vim)
        else
          @enteredKeys.push(vim, match.keyStr, @vimfx.options.timeout)
      else
        vim.hideNotification()

      if match.specialKeys['<late>']
        @suppress = false
        @consumeLateKeydown(vim, event, match)
      else
        @suppress = vim._onInput(match, event)
    else
      @suppress = null
    @setHeldModifiers(event)

  consumeLateKeydown: (vim, event, match) ->
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
          vim._onInput(match, event)
      @setHeldModifiers(event)
      return @suppress

    if vim.isUIEvent(event)
      @listenOnce('keydown', ((lateEvent) =>
        listener(lateEvent)
        if @suppress
          utils.suppressEvent(lateEvent)
          @listenOnce('keyup', utils.suppressEvent, false)
      ), false)
    else
      # Hack to avoid synchronous messages on every keydown (see
      # events-frame.coffee).
      prefs.set('late', true)
      vim._listenOnce('lateKeydown', listener)

  setHeldModifiers: (event, {filterCurrentOnly = false} = {}) ->
    mainWindow = @window.document.documentElement
    modifiers =
      if filterCurrentOnly
        mainWindow.getAttribute(HELD_MODIFIERS_ATTRIBUTE)
      else
        if @suppress == null then 'alt ctrl meta shift' else ''
    isHeld = (modifier) -> event["#{modifier}Key"]
    mainWindow.setAttribute(
      HELD_MODIFIERS_ATTRIBUTE, modifiers.split(' ').filter(isHeld).join(' ')
    )

  anyPopupsOpen: ->
    # The autocomplete popup in text inputs (for example) is technically a
    # panel, but it does not respond to key presses. Therefore
    # `[ignorekeys="true"]` is excluded.
    #
    # coffeelint: disable=max_line_length
    # <https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XUL/PopupGuide/PopupKeys#Ignoring_Keys>
    # coffeelint: enable=max_line_length
    popups = utils.querySelectorAllDeep(
      @window, ':-moz-any(menupopup, panel):not([ignorekeys="true"])'
    )
    for popup in popups
      return true if popup.state == 'open'
    return false

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
    clear = @clear.bind(this)
    @timeout = @window.setTimeout((-> clear(notifier)), duration)

  clearTimeout: ->
    @window.clearTimeout(@timeout) if @timeout?
    @timeout = null

module.exports = UIEventManager
