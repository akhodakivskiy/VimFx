utils                   = require 'utils'
{ modes }               = require 'modes'
{ isEscCommandKey
, isReturnCommandKey }  = require 'commands'

class Vim
  constructor: (@window) ->
    @storage = {}
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

  onKeydown: (event, keyStr) ->
    return modes[@mode].onKeydown?(@, @storage[@mode], event, keyStr)

  onClick: (event) ->
    modes[@mode].onClick?(@, @storage[@mode], event)

  onBlur: (event) ->
    modes[@mode].onBlur?(@, @storage[@mode], event)

  onFocus: (event) ->
    modes[@mode].onFocus?(@, @storage[@mode], event)

  onLocationChange: (event) ->
    modes[@mode].onLocationChange?(@, @storage[@mode], event)

exports.Vim = Vim
