utils = require 'utils'

{ commands
, hintCharHandler 
} = require 'commands'

{ getPref
, isCommandDisabled 
} = require 'prefs'


MODE_NORMAL = 1
MODE_HINTS  = 2

class Vim
  constructor: (@window) ->
    @mode     = MODE_NORMAL
    @keys     = []
    @lastKeyStr = null
    @markers  = undefined
    @cb       = undefined
    @findStr  = ""
    @findRng  = null

  enterHintsMode: (@markers, @cb) ->
    @mode = MODE_HINTS

  # TODO: This function should probably remove 
  # hint markers (if they are present) as well
  enterNormalMode: ->
    @mode = MODE_NORMAL
    @markers = @cb = undefined

  handleKeyDown: (keyboardEvent, keyStr) ->
    if @mode == MODE_NORMAL || keyStr == 'Esc'
      result = maybeCommand @keys.concat([keyStr])
    else if !keyboardEvent.ctrlKey and !keyboardEvent.metaKey
      if @mode == MODE_HINTS
        result = utils.getHintChars().search(regexpEscape(keyStr)) > -1

    if result 
      @lastKeyStr = keyStr
      @keys.push keyStr

    return result

  handleKeyPress: (keyboardEvent) ->
    lastKeyStr = if @keys.length > 0 then @keys[@keys.length - 1] else undefined
    if @mode == MODE_NORMAL or lastKeyStr == 'Esc'
      if command = findCommand @keys
        command @
        @keys.length = 0
        result = true
    else if !keyboardEvent.ctrlKey and !keyboardEvent.metaKey
      @keys.length = 0
      if @mode == MODE_HINTS
        hintCharHandler @, lastKeyStr, keyboardEvent.charCode
        result = true

    return result

findCommand = (keys) ->
  for i in [0...keys.length]
    seq = keys.slice(i).join(',')
    if com = commands[seq]
      if not isCommandDisabled(seq)
        return com

  return undefined

maybeCommand = (keys) ->
  for i in [0...keys.length]
    sequence = keys.slice(i).join(',')
    for seq, com of commands
      if seq.indexOf(sequence) == 0
        return not isCommandDisabled(seq)

  return false

exports.Vim = Vim
