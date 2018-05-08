# This file defines VimFx’s modes, and their respective commands. The Normal
# mode commands are defined in commands.coffee, though.

{commands, findStorage} = require('./commands')
defaults = require('./defaults')
help = require('./help')
hintsMode = require('./hints-mode')
prefs = require('./prefs')
SelectionManager = require('./selection')
translate = require('./translate')
utils = require('./utils')

{FORWARD, BACKWARD} = SelectionManager

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
    {vim, storage, event} = args
    {keyStr} = match
    focusTypeBeforeCommand = vim.focusType

    vim.hideNotification() if match.type in ['none', 'full']

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
    if vim.isUIEvent(event)
      # In browser UI the biggest reasons are allowing to reset the location bar
      # when blurring it, and closing dialogs such as the “bookmark this page”
      # dialog (<c-d>). However, an exception is made for the devtools (<c-K>).
      # There, trying to unfocus the devtools using Escape would annoyingly
      # open the split console.
      return utils.isDevtoolsElement(event.originalTarget)
    else
      # In web page content, an exception is made if an element that VimFx
      # cares about is focused. That allows for blurring an input in a custom
      # dialog without closing the dialog too. Note that running a command might
      # change `vim.focusType`, which is why this saved value is used here.
      return focusTypeBeforeCommand != 'none'

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
    vim._parent.resetCaretBrowsing(true)
    vim._run('enable_caret')

    listener = ->
      return unless newVim = vim._parent.getCurrentVim(vim.window)
      vim._parent.resetCaretBrowsing(
        if newVim.mode == 'caret' then true else null
      )
    vim._parent.on('TabSelect', listener)
    storage.removeListener = -> vim._parent.off('TabSelect', listener)

  onLeave: ({vim, storage}) ->
    vim._parent.resetCaretBrowsing()
    vim._run('clear_selection')
    storage.removeListener?()
    storage.removeListener = null

  onInput: (args, match) ->
    args.vim.hideNotification()

    # In case the user turns Caret Browsing off while in Caret mode.
    args.vim._parent.resetCaretBrowsing(true)

    switch match.type
      when 'full'
        match.command.run(args)
        return true
      when 'partial', 'count'
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
    {
      markerContainer, callback, matchText = true, count = 1, sleep = -1
    } = options
    storage.markerContainer = markerContainer
    storage.callback = callback
    storage.matchText = matchText
    storage.count = count
    storage.isMatched = {byText: false, byHint: false}
    storage.skipOnLeaveCleanup = false

    if matchText
      markerContainer.visualFeedbackUpdater =
        hintsMode.updateVisualFeedback.bind(null, vim)
      vim._run('clear_selection')

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
    hintsMode.cleanup(vim, storage) unless storage.skipOnLeaveCleanup

  onInput: (args, match) ->
    {vim, storage} = args
    {markerContainer, callback} = storage

    switch match.type
      when 'full'
        match.command.run(Object.assign({match}, args))

      when 'none', 'count'
        # Make sure notifications for counts aren’t shown.
        vim._refreshPersistentNotification()

        {char, isHintChar} = hintsMode.getChar(match, storage)
        return true unless char

        return true if storage.isMatched.byText and not isHintChar

        visibleMarkers = markerContainer.addChar(char, isHintChar)
        storage.isMatched = hintsMode.isMatched(visibleMarkers, markerContainer)

        if (storage.isMatched.byHint and isHintChar) or
           (storage.isMatched.byText and not isHintChar and
            vim.options['hints.auto_activate'])
          hintsMode.activateMatch(
            vim, storage, match, visibleMarkers, callback
          )

          unless isHintChar
            vim._parent.ignoreKeyEventsUntilTime =
              Date.now() + vim.options['hints.timeout']

    return true

}, {
  exit: ({vim}) ->
    vim._enterMode('normal')

  activate_highlighted: ({vim, storage, match}) ->
    {markerContainer: {markers, highlightedMarkers}, callback} = storage
    return if highlightedMarkers.length == 0

    for marker in markers when marker.visible
      marker.hide() unless marker in highlightedMarkers

    hintsMode.activateMatch(
      vim, storage, match, highlightedMarkers, callback
    )

  rotate_markers_forward: ({storage}) ->
    storage.markerContainer.rotateOverlapping(true)

  rotate_markers_backward: ({storage}) ->
    storage.markerContainer.rotateOverlapping(false)

  delete_char: ({storage}) ->
    {markerContainer} = storage
    visibleMarkers = markerContainer.deleteChar()
    storage.isMatched =
      hintsMode.isMatched(visibleMarkers or [], markerContainer)

  increase_count: ({storage}) ->
    storage.count += 1
    # Uncomment this line if you want to use `gulp hints.html`!
    # utils.writeToClipboard(storage.markerContainer.container.outerHTML)

  toggle_complementary: ({storage}) ->
    storage.markerContainer.toggleComplementary()
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
        switch match.type
          when 'full'
            match.command.run(args)
            return true
          when 'partial'
            return true

        # Make sure notifications for counts aren’t shown.
        vim.hideNotification()
        return false

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
    utils.getFindBar(vim.window.gBrowser).then((findBar) ->
      findStorage.lastSearchString = findBar._findField.value
      findStorage.busy = false
    )

  onInput: (args, match) ->
    {vim} = args
    switch
      when match.type == 'full'
        utils.getFindBar(vim.window.gBrowser, (findBar) ->
          args.findBar = findBar
          match.command.run(args)
        )
        return true
      when match.type == 'partial'
        return true
      when vim.focusType != 'findbar'
        # If we’re in Find mode but the find bar input hasn’t been focused yet,
        # suppress all input, because we don’t want to trigger Firefox commands,
        # such as `/` (which opens the Quick Find bar). This happens when
        # `helper_find_from_top_of_viewport` is slow, or when _Firefox_ is slow,
        # for example to due to heavy page loading. The following URL is a good
        # stress test: <https://html.spec.whatwg.org/>
        findStorage.busy = true
        return true
      else
        # At this point we know for sure that the find bar is not busy anymore.
        findStorage.busy = false
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
    switch match.type
      when 'full'
        match.command.run(args)
      when 'none', 'count'
        storage.callback(match.keyStr)
        vim._enterMode('normal')
    return true

}, {
  exit: ({vim}) ->
    vim.hideNotification()
    vim._enterMode('normal')
})
