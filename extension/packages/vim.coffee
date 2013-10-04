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

    # Esc key is not suppressed, and passed to the browser in `normal` mode.
    # Here we compare against the mode that was active before the key was processed 
    # because processing the command may change the mode.
    #
    # Not suppressing Esc allows for stopping the loading of the page as well as closing many custom
    # dialogs (and perhaps other things -- Esc is a very commonly used key). There are two reasons we
    # might suppress it in other modes. If some custom dialog of a website is open, we should be able to
    # cancel hint markers on it without closing it. Secondly, otherwise cancelling hint markers on
    # google causes its search bar to be focused.
    if oldMode == 'normal' and keyStr == 'Esc'
      return false
    else
      return suppress

exports.Vim = Vim
