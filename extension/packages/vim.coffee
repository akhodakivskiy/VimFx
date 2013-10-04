utils               = require 'utils'
{ modes }           = require 'modes'
{ isEscCommandKey } = require 'commands'

class Vim
  constructor: (@window) ->
    @storage = {}
    @enterMode('normal')

  enterMode: (mode, args) ->
    # `args` is an array of arguments to be passed to the mode's `onEnter` method
    if mode not of modes
      throw new Error("Not a valid VimFx mode to enter: #{ mode }")

    if @mode != mode
      if @mode of modes
        modes[@mode].onLeave(@, @storage[@mode], args)

      @mode = mode

      modes[@mode].onEnter(@, @storage[@mode] ?= {}, args)

  onInput: (keyStr, event) ->
    isEditable = utils.isElementEditable(event.originalTarget)

    if isEditable and not isEscCommandKey(keyStr)
      return false

    oldMode = @mode

    suppress = modes[@mode]?.onInput(@, @storage[@mode], keyStr, event)

    if oldMode == 'normal' and keyStr == 'Esc'
      return false
    else
      return suppress

exports.Vim = Vim
