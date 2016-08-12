###
# Copyright Anton Khodakivskiy 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
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

{commands, findStorage} = require('./commands')
defaults = require('./defaults')
help = require('./help')
prefs = require('./prefs')
SelectionManager = require('./selection')
translate = require('./translate')
utils = require('./utils')

{FORWARD, BACKWARD} = SelectionManager
CARET_BROWSING_PREF = 'accessibility.browsewithcaret'

# Helper to create modes in a DRY way.
mode = (modeName, obj, commands = null) ->
  obj.name = translate("mode.#{modeName}")
  obj.order = defaults.mode_order[modeName]
  obj.commands = {}
  for commandName, fn of commands
    pref = "mode.#{modeName}.#{commandName}"
    obj.commands[commandName] = {
      pref: defaults.BRANCH + pref
      run: fn
      category: defaults.categoryMap[pref]
      description: translate(pref)
      order: defaults.command_order[pref]
    }
  exports[modeName] = obj



mode('normal', {
  onEnter: ({vim, storage}, {returnTo = null} = {}) ->
    if returnTo
      storage.returnTo = returnTo
    else if storage.returnTo
      vim._enterMode(storage.returnTo)
      storage.returnTo = null

  onLeave: ({vim}) ->
    vim._run('clear_inputs')

  onInput: (args, match) ->
    {vim, storage, uiEvent} = args
    {keyStr} = match

    if match.type == 'none' or
       (match.likelyConflict and not match.specialKeys['<force>'])
      match.discard()
      if storage.returnTo
        vim._enterMode(storage.returnTo)
        storage.returnTo = null
      # If you press `aa` (and `a` is a prefix key, but there’s no `aa`
      # shortcut), don’t pass the second `a` to the page.
      return not match.toplevel

    if match.type == 'full'
      match.command.run(args)

      # If the command changed the mode, wait until coming back from that mode
      # before switching to `storage.returnTo` if any (see `onEnter` above).
      if storage.returnTo and vim.mode == 'normal'
        vim._enterMode(storage.returnTo)
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
      # dialog (<c-d>). However, an exception is made for the devtools (<c-K>).
      # There, trying to unfocus the devtools using Escape would annoyingly
      # open the split console.
      return utils.isDevtoolsElement(uiEvent.originalTarget)
    else
      # In web pages content, an exception is made if an element that VimFx
      # cares about is focused. That allows for blurring an input in a custom
      # dialog without closing the dialog too.
      return vim.focusType != 'none'

    # Note that this special handling of Escape is only used in Normal mode.
    # There are two reasons we might suppress it in other modes. If some custom
    # dialog of a website is open, we should be able to cancel hint markers on
    # it without closing it. Secondly, otherwise cancelling hint markers on
    # Google causes its search bar to be focused.

}, commands)



helper_move_caret = (method, direction, {vim, storage, count = 1}) ->
  vim._run('move_caret', {
    method, direction, select: storage.select
    count: if method == 'intraLineMove' then 1 else count
  })

mode('caret', {
  onEnter: ({vim, storage}, {select = false} = {}) ->
    storage.select = select
    storage.caretBrowsingPref = prefs.root.get(CARET_BROWSING_PREF)
    prefs.root.set(CARET_BROWSING_PREF, true)
    vim._run('enable_caret')

    listener = ->
      return unless newVim = vim._parent.getCurrentVim(vim.window)
      prefs.root.set(
        CARET_BROWSING_PREF,
        if newVim.mode == 'caret' then true else storage.caretBrowsingPref
      )
    vim._parent.on('TabSelect', listener)
    storage.removeListener = -> vim._parent.off('TabSelect', listener)

  onLeave: ({vim, storage}) ->
    prefs.root.set(CARET_BROWSING_PREF, storage.caretBrowsingPref)
    vim._run('clear_selection')
    storage.removeListener?()
    storage.removeListener = null

  onInput: (args, match) ->
    if match.type == 'full'
      match.command.run(args)
      return true
    return false

}, {
  # coffeelint: disable=colon_assignment_spacing
  move_left:          helper_move_caret.bind(null, 'characterMove',    BACKWARD)
  move_right:         helper_move_caret.bind(null, 'characterMove',    FORWARD)
  move_down:          helper_move_caret.bind(null, 'lineMove',         FORWARD)
  move_up:            helper_move_caret.bind(null, 'lineMove',         BACKWARD)
  move_word_left:     helper_move_caret.bind(null, 'wordMoveAdjusted', BACKWARD)
  move_word_right:    helper_move_caret.bind(null, 'wordMoveAdjusted', FORWARD)
  move_to_line_start: helper_move_caret.bind(null, 'intraLineMove',    BACKWARD)
  move_to_line_end:   helper_move_caret.bind(null, 'intraLineMove',    FORWARD)
  # coffeelint: enable=colon_assignment_spacing

  toggle_selection: ({vim, storage}) ->
    storage.select = not storage.select
    if storage.select
      vim.notify(translate('notification.toggle_selection.enter'))
    else
      vim._run('collapse_selection')

  toggle_selection_direction: ({vim}) ->
    vim._run('toggle_selection_direction')

  copy_selection_and_exit: ({vim}) ->
    vim._run('get_selection', null, (selection) ->
      # If the selection consists of newlines only, it _looks_ as if the
      # selection is collapsed, so don’t try to copy it in that case.
      if /^\n*$/.test(selection)
        vim.notify(translate('notification.copy_selection_and_exit.none'))
      else
        # Trigger this copying command instead of putting `selection` into the
        # clipboard, since `window.getSelection().toString()` sadly collapses
        # whitespace in `<pre>` elements.
        vim.window.goDoCommand('cmd_copy')
        vim._enterMode('normal')
    )

  exit: ({vim}) ->
    vim._enterMode('normal')
})



mode('hints', {
  onEnter: ({vim, storage}, options) ->
    {markerContainer, callback, count = 1, sleep = -1} = options
    storage.markerContainer = markerContainer
    storage.callback = callback
    storage.count = count
    storage.textChars = ''

    if sleep >= 0
      storage.clearInterval = utils.interval(vim.window, sleep, (next) ->
        if markerContainer.markers.length == 0
          next()
          return
        vim._send('getMarkableElementsMovements', null, (diffs) ->
          for {dx, dy}, index in diffs when not (dx == 0 and dy == 0)
            markerContainer.markerMap[index].updatePosition(dx, dy)
          next()
        )
      )

  onLeave: ({vim, storage}) ->
    {markerContainer} = storage
    vim.window.setTimeout(
      (-> markerContainer.remove()),
      vim.options.hints_timeout
    )
    storage.clearInterval?()
    for key of storage
      storage[key] = null
    return

  onInput: (args, match) ->
    {vim, storage} = args
    {markerContainer, callback} = storage

    if match.type == 'full'
      match.command.run(args)
    else if match.unmodifiedKey in vim.options.hint_chars
      matchedMarkers = markerContainer.matchHintChar(match.unmodifiedKey)
      if matchedMarkers.length > 0
        again = callback(matchedMarkers[0], storage.count, match.keyStr)
        storage.count -= 1
        storage.textChars = ''
        if again
          vim.window.setTimeout((->
            marker.markMatched(false) for marker in matchedMarkers
            return
          ), vim.options.hints_timeout)
          markerContainer.reset()
        else
          # The callback might have entered another mode. Only go back to Normal
          # mode if we’re still in Hints mode.
          vim._enterMode('normal') if vim.mode == 'hints'
    else
      matchedMarkers = markerContainer.matchTextChar(match.unmodifiedKey)
      storage.textChars += match.unmodifiedKey
      if matchedMarkers.length > 0
        again = callback(matchedMarkers[0], storage.count, match.keyStr)
        storage.count -= 1
        storage.textChars = ''
        if again
          vim.window.setTimeout((->
            marker.markMatched(false) for marker in matchedMarkers
            return
          ), vim.options.hints_timeout)
          markerContainer.reset()
        else
          # The callback might have entered another mode. Only go back to Normal
          # mode if we’re still in Hints mode.
          vim._enterMode('normal') if vim.mode == 'hints'

    if vim.options.notify_entered_keys
      vim.notify(storage.textChars) if storage.textChars
    return true

}, {
  exit: ({vim, storage}) ->
    # The hints are removed automatically when leaving the mode, but after a
    # timeout. When aborting the mode we should remove the hints immediately.
    storage.markerContainer.remove()
    vim._enterMode('normal')

  rotate_markers_forward: ({storage}) ->
    storage.markerContainer.rotateOverlapping(true)

  rotate_markers_backward: ({storage}) ->
    storage.markerContainer.rotateOverlapping(false)

  delete_hint_char: ({storage}) ->
    storage.markerContainer.deleteHintChar()
    storage.textChars = storage.textChars.slice(0, -1)

  increase_count: ({storage}) ->
    storage.count += 1

  toggle_complementary: ({storage}) ->
    storage.markerContainer.toggleComplementary()
    storage.textChars = ''
})



mode('ignore', {
  onEnter: ({vim, storage}, {count = null, type = null} = {}) ->
    storage.count = count

    # Keep last `.type` if no type was given. This is useful when returning to
    # Ignore mode after runnning the `unquote` command.
    if type
      storage.type = type
    else
      storage.type ?= 'explicit'

  onLeave: ({vim, storage}) ->
    unless storage.count? or storage.type == 'focusType'
      vim._run('blur_active_element')

  onInput: (args, match) ->
    {vim, storage} = args
    args.count = 1
    switch storage.count
      when null
        if match.type == 'full'
          match.command.run(args)
          return true
      when 1
        vim._enterMode('normal')
      else
        storage.count -= 1
    return false

}, {
  exit: ({vim, storage}) ->
    storage.type = null
    vim._enterMode('normal')
  unquote: ({vim}) ->
    vim._enterMode('normal', {returnTo: 'ignore'})
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
  exit: ({vim, findBar}) ->
    vim._enterMode('normal')
    findBar.close()
})



mode('marks', {
  onEnter: ({vim, storage}, callback) ->
    storage.callback = callback
    storage.timeoutId = vim.window.setTimeout((->
      vim.hideNotification()
      vim._enterMode('normal')
    ), vim.options.timeout)

  onLeave: ({vim, storage}) ->
    storage.callback = null
    vim.window.clearTimeout(storage.timeoutId) if storage.timeoutId?
    storage.timeoutId = null

  onInput: (args, match) ->
    {vim, storage} = args
    if match.type == 'full'
      match.command.run(args)
    else
      storage.callback(match.keyStr)
      vim._enterMode('normal')
    return true
}, {
  exit: ({vim}) ->
    vim._enterMode('normal')
})
