###
# Copyright Anton Khodakivskiy 2012, 2013.
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

# This file defines the `vim` API, available to all modes and commands. There is
# one `Vim` instance for each tab. Most importantly, it provides access to the
# owning Firefox window and the current mode, and allows you to change mode.
# `vim` objects are exposed by the Public API. Underscored names are private and
# should not be used by API consumers.

messageManager = require('./message-manager')
utils          = require('./utils')

class Vim
  constructor: (@browser, @_parent) ->
    @window = @browser.ownerGlobal
    @_messageManager = @browser.messageManager
    @_storage = {}

    @_resetState()

    Object.defineProperty(this, 'options', {
      get: => @_parent.options
      enumerable: true
    })

    @_onLocationChange(@browser.currentURI.spec)

    # Require the subset of the options needed to be listed explicitly (as
    # opposed to sending _all_ options) for performance. Each option access
    # might trigger an optionOverride.
    @_listen('options', ({ prefs }) =>
      options = {}
      for pref in prefs
        options[pref] = @options[pref]
      return options
    )

    @_listen('vimMethod', ({ method, args = [] }, { callback = null }) =>
      result = @[method](args...)
      @_send(callback, result) if callback
    )

    @_listen('vimMethodSync', ({ method, args = [] }) =>
      return @[method](args...)
    )

    @_listen('DOMWindowCreated', => @_state.frameCanReceiveEvents = true)

  _resetState: ->
    @_state =
      frameCanReceiveEvents: false
      lastUrl:               null

  _isBlacklisted: (url) -> @options.black_list.some((regex) -> regex.test(url))

  isFrameEvent: (event) ->
    return (@_state.frameCanReceiveEvents and
            event.originalTarget == @window.gBrowser.selectedBrowser)

  isCurrent: -> @_parent.getCurrentVim(utils.getCurrentWindow()) == this

  # `args` is an array of arguments to be passed to the mode's `onEnter` method.
  enterMode: (mode, args...) ->
    return false if @mode == mode

    unless utils.has(@_parent.modes, mode)
      modes = Object.keys(@_parent.modes).join(', ')
      throw new Error("VimFx: Unknown mode. Available modes are: #{ modes }.
                       Got: #{ mode }")

    @_call('onLeave') if @mode?
    @mode = mode
    @_call('onEnter', null, args...)
    @_parent.emit('modeChange', this)
    @_send('modeChange', {mode})
    return true

  _consumeKeyEvent: (event, focusType) ->
    return @_parent.consumeKeyEvent(event, this, focusType)

  _onInput: (match, { isFrameEvent = false } = {}) ->
    suppress = @_call('onInput', {isFrameEvent, count: match.count}, match)
    return suppress

  _onLocationChange: (url) ->
    return if url == @_state.lastUrl
    @_state.lastUrl = url
    @enterMode(if @_isBlacklisted(url) then 'ignore' else 'normal')
    @_parent.emit('locationChange', {vim: this, location: new @window.URL(url)})
    @_send('locationChange')

  _call: (method, data = {}, extraArgs...) ->
    args = Object.assign({vim: this, storage: @_storage[@mode] ?= {}}, data)
    currentMode = @_parent.modes[@mode]
    currentMode[method].call(currentMode, args, extraArgs...)

  _run: (name, data = {}, callback = null) ->
    @_send('runCommand', {name, data}, callback)

  _listen: (name, listener) ->
    messageManager.listen(name, listener, @_messageManager)

  _listenOnce: (name, listener) ->
    messageManager.listenOnce(name, listener, @_messageManager)

  _send: (name, data, callback = null) ->
    messageManager.send(name, data, @_messageManager, callback)

  notify: (title, options = {}) ->
    new @window.Notification(title, Object.assign({
      icon: 'chrome://vimfx/skin/icon128.png'
      tag: 'VimFx-notification'
    }, options))

  markPageInteraction: ->
    @_send('markPageInteraction')

  _focusMarkerElement: (elementIndex, options = {}) ->
    # If you, for example, focus the location bar, unfocus it by pressing
    # `<esc>` and then try to focus a link or text input in a web page the focus
    # won’t work unless `@browser` is focused first.
    @browser.focus()
    @_run('focus_marker_element', {elementIndex, options})

module.exports = Vim
