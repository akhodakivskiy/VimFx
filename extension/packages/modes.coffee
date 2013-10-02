utils                         = require 'utils'
{ mode_hints }                = require 'mode-hints/mode-hints'
{ updateToolbarButton }       = require 'button'
{ commands
, searchForMatchingCommand }  = require 'commands'

modes = {}

modes['normal'] = 
  onEnter: (vim, storage, args) ->
    storage.keys ?= []
    storage.commands ?= {}

  onLeave: (vim, storage, args) ->
    storage.keys.length = 0

  onInput: (vim, storage, keyStr, event) ->
    storage.keys.push(keyStr)

    runCommand = (command) ->
      commandStorage = storage.commands[command.name] ?= {}
      command.func(vim, commandStorage, event)

    { match, exact, command, index } = searchForMatchingCommand(storage.keys)

    if match
      storage.keys = storage.keys[index..]
      if exact
        runCommand(command)
      return keyStr != 'Esc'
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

modes['hints'] = mode_hints

exports.modes = modes
