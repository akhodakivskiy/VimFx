{ escapeCommand
, searchForMatchingCommand } = require 'commands'
{ modes }                    = require 'modes'

class Vim
  constructor: (@window) ->
    @storage = {}
    @enterMode('normal')

  enterMode: (mode, args) ->
    # `args` is an array of arguments to be passed to the mode's `onEnter` method
    if @mode != mode
      modes[@mode]?.onLeave(@, @storage[@mode], args)
      @mode = mode
      @storage[@mode] ?= {}
      modes[@mode]?.onEnter(@, @storage[@mode], args)

  onInput: (keyStr, event, options = {}) ->
    if options.autoInsertMode
      return false

    modes[@mode]?.onInput(@, @storage[@mode], keyStr, event)

    if searchForMatchingCommand([keyStr], [escapeCommand]).esc
      @enterMode('normal')

exports.Vim = Vim
