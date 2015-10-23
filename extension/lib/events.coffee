###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
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

# This file sets up all event listeners needed to power VimFx: To know when to
# launch commands and to provide state to them. Events in web page content are
# listened for in events-frame.coffee.

button = require('./button')
utils  = require('./utils')

HELD_MODIFIERS_ATTRIBUTE = 'vimfx-held-modifiers'

class UIEventManager
  constructor: (@vimfx, @window) ->
    @listen = utils.listen.bind(null, @window)
    @listenOnce = utils.listenOnce.bind(null, @window)

    # This flag controls whether to suppress the various key events or not.
    @suppress = false

    # When a menu or panel is shown VimFx should temporarily stop processing
    # keyboard input, allowing accesskeys to be used.
    @popupPassthrough = false

  addListeners: ->
    checkPassthrough = (value, event) =>
      target = event.originalTarget
      if target.nodeName in ['menupopup', 'panel']
        @popupPassthrough = value

    @listen('popupshown',  checkPassthrough.bind(null, true))
    @listen('popuphidden', checkPassthrough.bind(null, false))

    @listen('keydown', (event) =>
      try
        # No matter what, always reset the `suppress` flag, so we don't suppress
        # more than intended.
        @suppress = false

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

        if vim.isFrameEvent(event)
          vim._listenOnce('consumeKeyEvent', ({ focusType }) =>
            @consumeKeyEvent(vim, event, focusType, { isFrameEvent: true })
            return @suppress
          )
        else
          @consumeKeyEvent(vim, event, utils.getFocusType(event))
          # This also suppresses the 'keypress' event.
          utils.suppressEvent(event) if @suppress

      catch error
        console.error(utils.formatError(error))
    )

    @listen('keyup', (event) =>
      utils.suppressEvent(event) if @suppress
      @setHeldModifiers(event, {filterCurrentOnly: true})
    )

    checkFindbar = (mode, event) =>
      target = event.originalTarget
      findBar = @window.gBrowser.getFindBar()
      if target == findBar._findField.mInputField
        return unless vim = @vimfx.getCurrentVim(@window)
        vim.enterMode(mode)

    @listen('focus', (event) =>
      target = event.originalTarget

      if target == @window
        return unless vim = @vimfx.getCurrentVim(@window)
        vim._send('TabSelect')
        return

      checkFindbar('find', event)
    )
    @listen('blur', checkFindbar.bind(null, 'normal'))

    @listen('click', (event) =>
      target = event.originalTarget
      return unless vim = @vimfx.getCurrentVim(@window)

      # If the user clicks the reload button or a link when in hints mode, we’re
      # going to end up in hints mode without any markers. Or if the user clicks
      # a text input, then that input will be focused, but you can’t type in it
      # (instead markers will be matched). So if the user clicks anything in
      # hints mode it’s better to leave it.
      if vim.mode == 'hints' and not vim.isFrameEvent(event) and
         # Exclude the VimFx button, though, since clicking it returns to normal
         # mode. Otherwise we’d first return to normal mode and then the button
         # would open the help dialog.
         target != button.getButton(@window)
        vim.enterMode('normal')
    )

    @listen('TabSelect', (event) =>
      @vimfx.emit('TabSelect', event)

      return unless vim = @vimfx.getCurrentVim(@window)
      vim._send('TabSelect')
    )

    lastUrl = null
    progressListener =
      onLocationChange: (progress, request, location, flags) =>
        url     = location.spec
        refresh = (url == lastUrl)
        lastUrl = url
        unless flags & Ci.nsIWebProgressListener.LOCATION_CHANGE_SAME_DOCUMENT
          return unless vim = @vimfx.getCurrentVim(@window)
          vim._onLocationChange(url, {refresh})

    @window.gBrowser.addProgressListener(progressListener)
    module.onShutdown(=>
      @window.gBrowser.removeProgressListener(progressListener)
    )

  consumeKeyEvent: (vim, event, focusType, options = {}) ->
    match = vim._consumeKeyEvent(event, focusType)
    switch
      when not match
        @suppress = null
      when match.specialKeys['<late>']
        @suppress = false
        @consumeLateKeydown(vim, event, match, options)
      else
        @suppress = vim._onInput(match, options)
    @setHeldModifiers(event)

  consumeLateKeydown: (vim, event, match, options) ->
    { isFrameEvent = false } = options

    # The passed in `event` is the regular non-late browser UI keydown event.
    # It is only used to set held keys. This is easier than sending an event
    # subset from frame scripts.
    listener = ({ defaultPrevented }) =>
      @suppress =
        if defaultPrevented
          false
        else
          vim._onInput(match, options)
      @setHeldModifiers(event)
      return @suppress

    if isFrameEvent
      vim._listenOnce('lateKeydown', listener)
    else
      @listenOnce('keydown', ((lateEvent) =>
        listener(lateEvent)
        if @suppress
          utils.suppressEvent(lateEvent)
          @listenOnce('keyup', utils.suppressEvent, false)
      ), false)

  setHeldModifiers: (event, { filterCurrentOnly = false } = {}) ->
    mainWindow = @window.document.documentElement
    modifiers =
      if filterCurrentOnly
        mainWindow.getAttribute(HELD_MODIFIERS_ATTRIBUTE)
      else
        if @suppress == null then 'alt ctrl meta shift' else ''
    isHeld = (modifier) -> event["#{ modifier }Key"]
    mainWindow.setAttribute(HELD_MODIFIERS_ATTRIBUTE,
                            modifiers.split(' ').filter(isHeld).join(' '))

module.exports = UIEventManager
