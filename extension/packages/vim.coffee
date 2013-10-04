{ modes }           = require 'modes'
{ isEscCommandKey } = require 'commands'

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
    if options.autoInsertMode and not isEscCommandKey(keyStr)
      return false

    return modes[@mode]?.onInput(@, @storage[@mode], keyStr, event)

exports.Vim = Vim
