utils     = require 'utils'
{ modes } = require 'modes'

class Vim
  constructor: (@window) ->
    @rootWindow = utils.getRootWindow(@window) # For convenience.
    @storage = {}
    @loaded = false
    @lastLoad = Date.now()
    @enterMode('normal')

  enterMode: (mode, args...) ->
    # `args` is an array of arguments to be passed to the mode's `onEnter` method

    if mode not of modes
      throw new Error("Not a valid VimFx mode to enter: #{ mode }")

    if @mode != mode
      if @mode of modes
        modes[@mode].onLeave(@, @storage[@mode])

      @mode = mode

      modes[@mode].onEnter(@, @storage[@mode] ?= {}, args...)

  onInput: (keyStr, event) ->
    suppress = modes[@mode]?.onInput(@, @storage[@mode], keyStr, event)
    return suppress

exports.Vim = Vim
