###
# Copyright Anton Khodakivskiy 2013, 2014.
# Copyright Simon Lydell 2013, 2014.
# Copyright Wang Zhuochun 2014.
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

utils                        = require('./utils')
{ injectHints }              = require('./hints')
{ rotateOverlappingMarkers } = require('./marker')
{ updateToolbarButton }      = require('./button')
{ commands
, searchForMatchingCommand
, escapeCommand
, Command
, findStorage }              = require('./commands')

{ interfaces: Ci } = Components

XULDocument = Ci.nsIDOMXULDocument

exports['normal'] =
  onEnter: (vim, storage) ->
    storage.keys ?= []
    storage.commands ?= {}

  onLeave: (vim, storage) ->
    storage.keys.length = 0

  onInput: (vim, storage, keyStr, event) ->
    target = event.originalTarget
    document = target.ownerDocument

    autoInsertMode = \
      utils.isTextInputElement(target) or
      utils.isContentEditable(target) or
      (utils.isActivatable(target) and keyStr == '<enter>') or
      (utils.isAdjustable(target) and keyStr in [
        '<arrowup>', '<arrowdown>', '<arrowleft>', '<arrowright>'
        '<space>', '<enter>'
      ]) or
      vim.rootWindow.TabView.isVisible() or
      document.fullscreenElement or document.mozFullScreenElement

    storage.keys.push(keyStr)

    { match, exact, command, count } = searchForMatchingCommand(storage.keys)

    if vim.state.blacklistedKeys and
       storage.keys.join('') in vim.state.blacklistedKeys
      match = false

    if match

      if autoInsertMode and command != escapeCommand
        storage.keys.pop()
        return false

      if exact
        command.func(vim, event, count)
        storage.keys.length = 0

      # Esc key is not suppressed, and passed to the browser in normal mode.
      #
      # - It allows for stopping the loading of the page.
      # - It allows for closing many custom dialogs (and perhaps other things
      #   -- Esc is a very commonly used key).
      # - It is not passed if Esc is used for `command_Esc` and we’re blurring
      #   an element. That allows for blurring an input in a custom dialog
      #   without closing the dialog too.
      # - There are two reasons we might suppress it in other modes. If some
      #   custom dialog of a website is open, we should be able to cancel hint
      #   markers on it without closing it. Secondly, otherwise cancelling hint
      #   markers on Google causes its search bar to be focused.
      # - It may only be suppressed in web pages, not in browser chrome. That
      #   allows for reseting the location bar when blurring it, and closing
      #   dialogs such as the “bookmark this page” dialog (<c-d>).
      inBrowserChrome = (document instanceof XULDocument)
      if keyStr == '<escape>' and (not autoInsertMode or inBrowserChrome)
        return false

      return true

    else
      storage.keys.length = 0 unless /^\d$/.test(keyStr)

      return false

  commands: commands

exports['insert'] =
  onEnter: (vim, storage, count = null) ->
    storage.count = count
    updateToolbarButton(vim.rootWindow, {insertMode: true})
  onLeave: (vim) ->
    updateToolbarButton(vim.rootWindow, {insertMode: false})
    utils.blurActiveElement(vim.window)
  onInput: (vim, storage, keyStr) ->
    switch storage.count
      when null
        if @commands['exit'].match(keyStr)
          vim.enterMode('normal')
          return true
      when 1
        vim.enterMode('normal')
      else
        storage.count--
    return false
  commands:
    exit: ['<s-escape>']

exports['find'] =
  onEnter: ->

  onLeave: (vim) ->
    findBar = vim.rootWindow.gBrowser.getFindBar()
    findStorage.lastSearchString = findBar._findField.value

  onInput: (vim, storage, keyStr) ->
    findBar = vim.rootWindow.gBrowser.getFindBar()
    if @commands['exit'].match(keyStr)
      findBar.close()
      return true
    return false

  commands:
    exit: ['<escape>', '<enter>']

exports['hints'] =
  onEnter: (vim, storage, filter, callback) ->
    [ markers, container ] = injectHints(vim.rootWindow, vim.window, filter)
    if markers.length > 0
      storage.markers   = markers
      storage.container = container
      storage.callback  = callback
      storage.numEnteredChars = 0
    else
      vim.enterMode('normal')

  onLeave: (vim, storage) ->
    { container } = storage
    vim.rootWindow.setTimeout((->
      container?.remove()
    ), @timeout)
    for key of storage
      storage[key] = null

  onInput: (vim, storage, keyStr, event) ->
    { markers, callback } = storage

    switch
      when @commands['exit'].match(keyStr)
        # Remove the hints immediately.
        storage.container?.remove()
        vim.enterMode('normal')
        return true

      when @commands['rotate_markers_forward'].match(keyStr)
        rotateOverlappingMarkers(markers, true)
      when @commands['rotate_markers_backward'].match(keyStr)
        rotateOverlappingMarkers(markers, false)

      when @commands['delete_hint_char'].match(keyStr)
        for marker in markers
          switch marker.hintIndex - storage.numEnteredChars
            when  0 then marker.deleteHintChar()
            when -1 then marker.show()
        storage.numEnteredChars-- unless storage.numEnteredChars == 0

      else
        if keyStr not in utils.getHintChars()
          return true
        matchedMarkers = []
        for marker in markers when marker.hintIndex == storage.numEnteredChars
          match = marker.matchHintChar(keyStr)
          marker.hide() unless match
          if marker.isMatched()
            marker.markMatched(true)
            matchedMarkers.push(marker)
        if matchedMarkers.length > 0
          again = callback(matchedMarkers[0])
          if again
            vim.rootWindow.setTimeout((->
              marker.markMatched(false) for marker in matchedMarkers
            ), @timeout)
            marker.reset() for marker in markers
            storage.numEnteredChars = 0
          else
            vim.enterMode('normal')
          return true
        storage.numEnteredChars++

    return true

  timeout: 200

  commands:
    exit:                    ['<escape>']
    rotate_markers_forward:  ['<space>']
    rotate_markers_backward: ['<s-space>']
    delete_hint_char:        ['<backspace>']

for modeName of exports
  mode = exports[modeName]
  continue if Array.isArray(mode.commands)
  for commandName of mode.commands
    name = "mode_#{ modeName }_#{ commandName }"
    keys = mode.commands[commandName].map((key) -> [key])
    mode.commands[commandName] = new Command(null, name, null, keys)
