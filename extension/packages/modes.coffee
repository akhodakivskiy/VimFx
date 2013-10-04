utils                         = require 'utils'
{ mode_hints }                = require 'mode-hints/mode-hints'
{ updateToolbarButton }       = require 'button'
{ searchForMatchingCommand
, isEscCommandKey }  = require 'commands'

modes = {}

modes['normal'] = 
  onEnter: (vim, storage, args) ->
    storage.keys ?= []
    storage.commands ?= {}

  onLeave: (vim, storage, args) ->
    storage.keys.length = 0

  onInput: (vim, storage, keyStr, event) ->
    storage.keys.push(keyStr)

    { match, exact, command } = searchForMatchingCommand(storage.keys)

    if match
      if exact
        commandStorage = storage.commands[command.name] ?= {}
        command.func(vim, commandStorage, event)
        storage.keys.length = 0
      return true
    else
      storage.keys.length = 0

modes['insert'] =
  onEnter: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: true})
  onLeave: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: false})
    utils.blurActiveElement(vim.window)
  onInput: (vim, storage, keyStr) ->
    if isEscCommandKey(keyStr)
      vim.enterMode('normal')
      return true

modes['hints'] = mode_hints

exports.modes = modes
