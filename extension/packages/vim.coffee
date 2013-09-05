utils = require 'utils'

commands = require 'commands'

{ getPref
, isCommandDisabled
} = require 'prefs'

MODE_NORMAL = 1
MODE_HINTS  = 2

class Vim
  @findStr = ''

  constructor: (@window) ->
    @mode       = MODE_NORMAL
    @keys       = []
    @lastKeyStr = null
    @markers    = undefined
    @cb         = undefined
    @findRng    = null
    @suppress   = false

    Object.defineProperty(this, 'findStr',
      get: -> return Vim.findStr
      set: (value) -> Vim.findStr = value
    )

  enterHintsMode: (@markers, @cb) ->
    @mode = MODE_HINTS

  # TODO: This function should probably remove
  # hint markers (if they are present) as well
  enterNormalMode: ->
    @mode = MODE_NORMAL
    @markers = @cb = undefined

  handleKeyDown: (event, keyStr) ->
    @suppress = true
    if @mode == MODE_NORMAL || keyStr == 'Esc'
      @keys.push(keyStr)
      @lastKeyStr = keyStr
      if command = commands.findCommand(@keys)
        command.func(@)
        return command.name != 'Esc'
      else if commands.maybeCommand(@keys)
        return true
      else
        @keys.length = 0
    else if @mode == MODE_HINTS and not (event.ctrlKey or event.metaKey)
      specialKeys = ['Shift-Space', 'Space', 'Backspace']
      if utils.getHintChars().search(utils.regexpEscape(keyStr)) > -1 or keyStr in specialKeys
        commands.hintCharHandler(@, keyStr)
        return true

    @suppress = false
    @keys.length = 0
    return false

  handleKeyPress: (event, keyStr) ->
    return @lastKeyStr != 'Esc' and @suppress

  handleKeyUp: (event) ->
    sup = @suppress
    @suppress = false
    return @lastKeyStr != 'Esc' and sup

exports.Vim = Vim
