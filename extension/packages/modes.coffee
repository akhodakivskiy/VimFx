utils                   = require 'utils'
{ mode_hints }          = require 'mode-hints/mode-hints'
{ updateToolbarButton } = require 'button'
{ searchForMatchingCommand
, escapeCommand
, findStorage }         = require 'commands'

modes = {}

modes['normal'] =
  onEnter: (vim, storage) ->
    storage.keys ?= []

  onLeave: (vim, storage) ->
    storage.keys.length = 0

  onKeydown: (vim, storage, event, keyStr) ->
    storage.keys.push(keyStr)

    { match, exact, command } = searchForMatchingCommand(storage.keys)

    if match
      if exact
        command.func(vim, event)
        storage.keys.length = 0
      return true unless keyStr == 'Esc'
      # Esc key is not suppressed, and passed to the browser in normal mode.
      # Not suppressing Esc allows for stopping the loading of the page as well as
      # closing many custom dialogs (and perhaps other things -- Esc is a very
      # commonly used key). There are two reasons we might suppress it in other
      # modes. If some custom dialog of a website is open, we should be able to
      # cancel hint markers on it without closing it. Secondly, otherwise
      # cancelling hint markers on google causes its search bar to be focused.
    else
      storage.keys.length = 0
      return false

  onClick: (vim, storage, event) ->
    if utils.isElementEditable(event.target)
       vim.enterMode('insert', {auto: true})

  onFocus: (vim, storage, event) ->
    target = event.originalTarget
    if utils.isElementEditable(target)
      if not vim.window.document.contains(target) or \
          vim.lastNonCommandKeyStr == 'Tab'
        vim.enterMode('insert', {auto: true})


modes['insert'] =
  onEnter: (vim, storage, options = {}) ->
    storage.auto = options.auto
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: true})

  onLeave: (vim, storage) ->
    storage.auto = undefined
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: false})

  onKeydown: (vim, storage, event, keyStr) ->
    if keyStr in escapeCommand.keys()
      escapeCommand.func(vim, event)
      vim.enterMode('normal')
      return true

  onBlur: (vim, storage, event) ->
    # If insert mode was entered automatically (when clicking a text input,
    # using the 'f' command, using the 'o' command etc.), go back to normal
    # mode automatically too when the text input is blurred.
    if storage.auto
      vim.enterMode('normal')


modes['find'] =
  onEnter: (vim, storage, options) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()

    findBar.onFindCommand()
    findBar._findField.focus()
    findBar._findField.select()

    return unless highlightButton = findBar.getElement("highlight")
    return unless highlightButton.checked != options.highlight
    highlightButton.click()

  onLeave: (vim, storage) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()
    findStorage.lastSearchString = findBar._findField.value
    findBar.close()

  onKeydown: (vim, storage, event, keyStr) ->
    return unless findBar = utils.getRootWindow(vim.window)?.gBrowser.getFindBar()
    if keyStr in escapeCommand.keys() or keyStr == 'Return'
      vim.enterMode('normal')
      return true
    else
      findBar._findField.focus()


modes['hints'] = mode_hints


exports.modes = modes
