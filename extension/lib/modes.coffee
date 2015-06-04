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

{ commands
, findStorage }              = require('./commands')
defaults                     = require('./defaults')
help                         = require('./help')
hints                        = require('./hints')
translate                    = require('./l10n')
{ rotateOverlappingMarkers } = require('./marker')
utils                        = require('./utils')

{ interfaces: Ci } = Components

XULDocument = Ci.nsIDOMXULDocument

# Helper to create modes in a DRY way.
mode = (modeName, obj, commands) ->
  obj.name  = translate.bind(null, "mode.#{ modeName }")
  obj.order = defaults.mode_order[modeName]
  obj.commands = {}
  for commandName, fn of commands
    pref = "mode.#{ modeName }.#{ commandName }"
    obj.commands[commandName] =
      pref:        defaults.BRANCH + pref
      run:         fn
      category:    defaults.categoryMap[pref]
      description: translate.bind(null, pref)
      order:       defaults.command_order[pref]
  exports[modeName] = obj



mode('normal', {
  onEnter: ->

  onLeave: ({ vim }) ->
    help.removeHelp(vim.rootWindow)

  onInput: (args, match) ->
    { vim, storage, event } = args
    target = event.originalTarget
    document = target.ownerDocument

    { activatable_element_keys, adjustable_element_keys } = vim.parent.options
    autoInsertMode = \
      utils.isTextInputElement(target) or
      utils.isContentEditable(target) or
      (utils.isActivatable(target) and
       match.keyStr in activatable_element_keys) or
      (utils.isAdjustable(target) and
       match.keyStr in adjustable_element_keys) or
      vim.rootWindow.TabView.isVisible() or
      document.fullscreenElement or document.mozFullScreenElement

    return false if match.type == 'none' or (autoInsertMode and not match.force)

    match.command.run(args) if match.type == 'full'

    # At this point the match is either full, partial or part of a count. Then
    # we always want to suppress, except for one case: The Escape key.
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
    if match.keyStr == '<escape>' and (not autoInsertMode or inBrowserChrome)
      return false

    return true

}, commands)



mode('hints', {
  onEnter: ({ vim, storage, args: [ filter, callback ] }) ->
    [ markers, container ] = hints.injectHints(
      vim.rootWindow, vim.window, filter, vim.parent.options
    )
    if markers.length > 0
      storage.markers   = markers
      storage.container = container
      storage.callback  = callback
      storage.numEnteredChars = 0
    else
      vim.enterMode('normal')

  onLeave: ({ vim, storage }) ->
    { container } = storage
    vim.rootWindow.setTimeout((->
      container?.remove()
    ), vim.parent.options.hints_timeout)
    for key of storage
      storage[key] = null

  onInput: (args, match) ->
    { vim, storage } = args
    { markers, callback } = storage

    if match.type == 'full'
      match.command.run(args)
    else if match.keyStr in vim.parent.options.hint_chars
      matchedMarkers = []

      for marker in markers when marker.hintIndex == storage.numEnteredChars
        matched = marker.matchHintChar(match.keyStr)
        marker.hide() unless matched
        if marker.isMatched()
          marker.markMatched(true)
          matchedMarkers.push(marker)

      if matchedMarkers.length > 0
        again = callback(matchedMarkers[0])
        if again
          vim.rootWindow.setTimeout((->
            marker.markMatched(false) for marker in matchedMarkers
          ), vim.parent.options.hints_timeout)
          marker.reset() for marker in markers
          storage.numEnteredChars = 0
        else
          vim.enterMode('normal')
      else
        storage.numEnteredChars++

    return true

}, {
  exit: ({ vim, storage }) ->
    # The hints are removed automatically when leaving the mode, but after a
    # timeout. When aborting the mode we should remove the hints immediately.
    storage.container?.remove()
    vim.enterMode('normal')

  rotate_markers_forward: ({ storage }) ->
    rotateOverlappingMarkers(storage.markers, true)

  rotate_markers_backward: ({ storage }) ->
    rotateOverlappingMarkers(storage.markers, false)

  delete_hint_char: ({ storage }) ->
    for marker in storage.markers
      switch marker.hintIndex - storage.numEnteredChars
        when  0 then marker.deleteHintChar()
        when -1 then marker.show()
    storage.numEnteredChars-- unless storage.numEnteredChars == 0
})



mode('insert', {
  onEnter: ({ vim, storage, args: [ count ] }) ->
    storage.count = count ? null

  onLeave: ({ vim }) ->
    utils.blurActiveElement(vim.window)

  onInput: (args, match) ->
    { vim, storage } = args
    switch storage.count
      when null
        if match.type == 'full'
          match.command.run(args)
          return true
      when 1
        vim.enterMode('normal')
      else
        storage.count--
    return false

}, {
  exit: ({ vim }) -> vim.enterMode('normal')
})



mode('text_input', {
  onEnter: ({ vim, storage, args: [ inputs ] }) ->
    storage.inputs = inputs

  onLeave: ({ vim, storage }) ->
    storage.inputs = null

  onInput: (args, match) ->
    { vim, storage: { inputs } } = args
    index = inputs.indexOf(vim.window.document.activeElement)
    if index == -1
      vim.enterMode('normal')
      return false
    return false unless match.type == 'full'
    diff = match.command.run(args)
    inputs[(index + diff) %% inputs.length].select() unless diff == 0
    return true

}, {
  exit: ({ vim }) ->
    utils.blurActiveElement(vim.window)
    vim.enterMode('normal')
    return 0
  input_previous: -> -1
  input_next:     -> +1
})



mode('find', {
  onEnter: ->

  onLeave: ({ vim }) ->
    findBar = vim.rootWindow.gBrowser.getFindBar()
    findStorage.lastSearchString = findBar._findField.value

  onInput: (args, match) ->
    args.findBar = args.vim.rootWindow.gBrowser.getFindBar()
    if match.type == 'full'
      match.command.run(args)
      return true
    return false

}, {
  exit: ({ findBar }) -> findBar.close()
})
