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

# This file defines the `vim` API, available to all modes and commands. There is
# one `Vim` instance for each tab. Most importantly, it provides access to the
# owning Firefox window and the current mode, and allows you to change mode.
# `vim` objects are exposed by the Public API. Underscored names are private and
# should not be used by API consumers.

messageManager     = require('./message-manager')
ScrollableElements = require('./scrollable-elements')
statusPanel        = require('./status-panel')
utils              = require('./utils')

ChromeWindow = Ci.nsIDOMChromeWindow

class Vim
  constructor: (browser, @_parent) ->
    @_setBrowser(browser, {addListeners: false})
    @_storage = {}

    @_resetState()

    Object.defineProperty(this, 'options', {
      get: => @_parent.options
      enumerable: true
    })

    # Since this is done in the constructor, defer location change handling to
    # the next tick so that this `vim` instance is saved in `vimfx.vims` first.
    # This allows 'locationChange' listeners to use `@vimfx.getCurrentVim()`.
    utils.nextTick(@window, =>
      @_onLocationChange(@browser.currentURI.spec)
    )

    @_addListeners()

  _addListeners: ->
    # Require the subset of the options needed to be listed explicitly (as
    # opposed to sending _all_ options) for performance. Each option access
    # might trigger an optionOverride.
    @_listen('options', ({prefs}) =>
      options = {}
      for pref in prefs
        options[pref] = @options[pref]
      return options
    )

    @_listen('vimMethod', ({method, args = []}, {callback = null}) =>
      result = @[method](args...)
      @_send(callback, result) if callback
    )

    @_listen('vimMethodSync', ({method, args = []}) =>
      return @[method](args...)
    )

    @_listen('DOMWindowCreated', => @_state.frameCanReceiveEvents = true)

    @_listen('locationChange', @_onLocationChange.bind(this))

    @_listen('focusType', (focusType) =>
      # If the focus moves from a web page element to a browser UI element, the
      # focus and blur events happen in the expected order, but the message from
      # the frame script arrives too late. Therefore, check that the currently
      # active element isn’t a browser UI element first.
      unless @_isUIElement(utils.getActiveElement(@window))
        @_parent.emit('focusTypeChange', {vim: this, focusType})
    )

  _setBrowser: (@browser, {addListeners = true} = {}) ->
    @window = @browser.ownerGlobal
    @_messageManager = @browser.messageManager

    @_statusPanel?.remove()
    @_statusPanel = statusPanel.injectStatusPanel(@browser)
    @_statusPanel.onclick = @hideNotification.bind(this)

    @_addListeners() if addListeners

  _resetState: ->
    @_state =
      frameCanReceiveEvents: false
      scrollableElements:    new ScrollableElements(@window)

  _isBlacklisted: (url) -> @options.black_list.some((regex) -> regex.test(url))

  isUIEvent: (event) ->
    return not @_state.frameCanReceiveEvents or
           @_isUIElement(event.originalTarget)

  _isUIElement: (element) ->
    # TODO: The `element.ownerGlobal` check will be redundant when
    # non-multi-process is removed from Firefox.
    return element.ownerGlobal instanceof ChromeWindow and
           element != @window.gBrowser.selectedBrowser

  # `args...` is passed to the mode's `onEnter` method.
  enterMode: (mode, args...) ->
    return if @mode == mode

    unless utils.has(@_parent.modes, mode)
      modes = Object.keys(@_parent.modes).join(', ')
      throw new Error("VimFx: Unknown mode. Available modes are: #{modes}.
                       Got: #{mode}")

    @_call('onLeave') if @mode?
    @mode = mode
    result = @_call('onEnter', null, args...)
    @_parent.emit('modeChange', this)
    @_send('modeChange', {mode})
    return result

  _consumeKeyEvent: (event, focusType) ->
    return @_parent.consumeKeyEvent(event, this, focusType)

  _onInput: (match, uiEvent = false) ->
    suppress = @_call('onInput', {uiEvent, count: match.count}, match)
    return suppress

  _onLocationChange: (url) ->
    @enterMode(if @_isBlacklisted(url) then 'ignore' else 'normal')
    @_parent.emit('locationChange', {vim: this, location: new @window.URL(url)})

  _call: (method, data = {}, extraArgs...) ->
    args = Object.assign({vim: this, storage: @_storage[@mode] ?= {}}, data)
    currentMode = @_parent.modes[@mode]
    return currentMode[method].call(currentMode, args, extraArgs...)

  _run: (name, data = {}, callback = null) ->
    @_send('runCommand', {name, data}, callback)

  _listen: (name, listener) ->
    messageManager.listen(name, listener, @_messageManager)

  _listenOnce: (name, listener) ->
    messageManager.listenOnce(name, listener, @_messageManager)

  _send: (name, data, callback = null) ->
    messageManager.send(name, data, @_messageManager, callback)

  notify: (message) ->
    @_parent.emit('notification', {vim: this, message})
    if @_parent.options.notifications_enabled
      @_statusPanel.setAttribute('label', message)
      @_statusPanel.removeAttribute('inactive')

  hideNotification: ->
    @_parent.emit('hideNotification', {vim: this})
    @_statusPanel.setAttribute('inactive', 'true')

  markPageInteraction: ->
    @_send('markPageInteraction')

  _focusMarkerElement: (elementIndex, options = {}) ->
    # If you, for example, focus the location bar, unfocus it by pressing
    # `<esc>` and then try to focus a link or text input in a web page the focus
    # won’t work unless `@browser` is focused first.
    @browser.focus()
    @_run('focus_marker_element', {elementIndex, options})

module.exports = Vim
