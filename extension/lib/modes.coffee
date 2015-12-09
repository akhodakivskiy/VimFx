###
# Copyright Anton Khodakivskiy 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015.
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

# This file defines VimFx’s modes, and their respective commands. The Normal
# mode commands are defined in commands.coffee, though.

{commands, findStorage}    = require('./commands')
defaults                   = require('./defaults')
help                       = require('./help')
hints                      = require('./hints')
translate                  = require('./l10n')
{rotateOverlappingMarkers} = require('./marker')
utils                      = require('./utils')

# Helper to create modes in a DRY way.
mode = (modeName, obj, commands = null) ->
  obj.name  = translate.bind(null, "mode.#{modeName}")
  obj.order = defaults.mode_order[modeName]
  obj.commands = {}
  for commandName, fn of commands
    pref = "mode.#{modeName}.#{commandName}"
    obj.commands[commandName] =
      pref:        defaults.BRANCH + pref
      run:         fn
      category:    defaults.categoryMap[pref]
      description: translate.bind(null, pref)
      order:       defaults.command_order[pref]
  exports[modeName] = obj



mode('normal', {
  onEnter: ({vim, storage}, options = {}) ->
    if options.returnTo
      storage.returnTo = options.returnTo
    else if storage.returnTo
      vim.enterMode(storage.returnTo)
      storage.returnTo = null

  onLeave: ({vim}) ->
    vim._run('clear_inputs')
    help.removeHelp(vim.window)

  onInput: (args, match) ->
    {vim, storage, uiEvent} = args
    {keyStr} = match

    autoInsertMode = (match.focus != null)
    if match.type == 'none' or
       (autoInsertMode and not match.specialKeys['<force>'])
      match.discard()
      if storage.returnTo
        vim.enterMode(storage.returnTo)
        storage.returnTo = null
      return false

    if match.type == 'full'
      match.command.run(args)

      # If the command changed the mode, wait until coming back from that mode
      # before switching to `storage.returnTo` if any (see `onEnter` above).
      if storage.returnTo and vim.mode == 'normal'
        vim.enterMode(storage.returnTo)
        storage.returnTo = null

    # At this point the match is either full, partial or part of a count. Then
    # we always want to suppress, except for one case: The Escape key.
    return true unless keyStr == '<escape>'

    # Passing Escape through allows for stopping the loading of the page and
    # closing many custom dialogs (and perhaps other things; Escape is a very
    # commonly used key).
    if uiEvent
      # In browser UI the biggest reasons are allowing to reset the location bar
      # when blurring it, and closing dialogs such as the “bookmark this page”
      # dialog (<c-d>). However, an exception is made for the dev tools (<c-K>).
      # There, trying to unfocus the dev tools using Escape would annoyingly
      # open the split console.
      return uiEvent.originalTarget.ownerGlobal.DevTools?
    else
      # In web pages content, an exception is made if we’re in autoInsertMode.
      # That allows for blurring an input in a custom dialog without closing the
      # dialog too.
      return autoInsertMode

    # Note that this special handling of Escape is only used in Normal mode.
    # There are two reasons we might suppress it in other modes. If some custom
    # dialog of a website is open, we should be able to cancel hint markers on
    # it without closing it. Secondly, otherwise cancelling hint markers on
    # Google causes its search bar to be focused.

}, commands)



mode('hints', {
  onEnter: ({vim, storage}, markers, callback, count = 1) ->
    storage.markers  = markers
    storage.callback = callback
    storage.count    = count
    storage.numEnteredChars = 0

    # Expose the storage so asynchronously computed markers can be set
    # retroactively.
    return storage

  onLeave: ({vim, storage}) ->
    vim.window.setTimeout(hints.removeHints.bind(null, vim.window),
                          vim.options.hints_timeout)
    for key of storage
      storage[key] = null
    return

  onInput: (args, match) ->
    {vim, storage} = args
    {markers, callback} = storage

    if match.type == 'full'
      match.command.run(args)
    else if match.unmodifiedKey in vim.options.hint_chars and markers.length > 0
      matchedMarkers = []

      for marker in markers when marker.hintIndex == storage.numEnteredChars
        matched = marker.matchHintChar(match.unmodifiedKey)
        marker.hide() unless matched
        if marker.isMatched()
          marker.markMatched(true)
          matchedMarkers.push(marker)

      if matchedMarkers.length > 0
        again = callback(matchedMarkers[0], storage.count, match.keyStr)
        storage.count--
        if again
          vim.window.setTimeout((->
            marker.markMatched(false) for marker in matchedMarkers
            return
          ), vim.options.hints_timeout)
          marker.reset() for marker in markers
          storage.numEnteredChars = 0
        else
          vim.enterMode('normal')
      else
        storage.numEnteredChars++

    return true

}, {
  exit: ({vim, storage}) ->
    # The hints are removed automatically when leaving the mode, but after a
    # timeout. When aborting the mode we should remove the hints immediately.
    hints.removeHints(vim.window)
    vim.enterMode('normal')

  rotate_markers_forward: ({storage}) ->
    rotateOverlappingMarkers(storage.markers, true)

  rotate_markers_backward: ({storage}) ->
    rotateOverlappingMarkers(storage.markers, false)

  delete_hint_char: ({storage}) ->
    for marker in storage.markers
      switch marker.hintIndex - storage.numEnteredChars
        when  0 then marker.deleteHintChar()
        when -1 then marker.show()
    storage.numEnteredChars-- unless storage.numEnteredChars == 0

  increase_count: ({storage}) -> storage.count++
})



mode('ignore', {
  onEnter: ({vim, storage}, count = null) ->
    storage.count = count

  onLeave: ({vim, storage}) ->
    vim._run('blur_active_element') unless storage.count?

  onInput: (args, match) ->
    {vim, storage} = args
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
  exit:    ({vim}) -> vim.enterMode('normal')
  unquote: ({vim}) -> vim.enterMode('normal', {returnTo: 'ignore'})
})



mode('find', {
  onEnter: ->

  onLeave: ({vim}) ->
    findBar = vim.window.gBrowser.getFindBar()
    findStorage.lastSearchString = findBar._findField.value

  onInput: (args, match) ->
    args.findBar = args.vim.window.gBrowser.getFindBar()
    if match.type == 'full'
      match.command.run(args)
      return true
    return false

}, {
  exit: ({findBar}) -> findBar.close()
})



mode('marks', {
  onEnter: ({storage}, callback) ->
    storage.callback = callback

  onLeave: ({storage}) ->
    storage.callback = null

  onInput: (args, match) ->
    {vim, storage} = args
    storage.callback(match.keyStr)
    vim.enterMode('normal')
    return true
})
