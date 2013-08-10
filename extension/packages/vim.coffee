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

  handleKeyDown: (keyboardEvent, keyStr) ->
    if @mode == MODE_NORMAL || keyStr == 'Esc'
      result = commands.maybeCommand(@keys.concat([keyStr]))
    else if !keyboardEvent.ctrlKey and !keyboardEvent.metaKey
      if @mode == MODE_HINTS
        result = utils.getHintChars().search(utils.regexpEscape(keyStr)) > -1

    if result
      @lastKeyStr = keyStr
      @keys.push keyStr

    return result

  handleKeyPress: (keyboardEvent) ->
    lastKeyStr = if @keys.length > 0 then @keys[@keys.length - 1] else undefined
    if @mode == MODE_NORMAL or lastKeyStr == 'Esc'
      if command = commands.findCommand(@keys)
        command.func(@)
        @keys.length = 0
        result = true
    else if !keyboardEvent.ctrlKey and !keyboardEvent.metaKey
      @keys.length = 0
      if @mode == MODE_HINTS
        commands.hintCharHandler(@, lastKeyStr, keyboardEvent.charCode)
        result = true

    return result

exports.Vim = Vim
