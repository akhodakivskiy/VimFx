utils = require 'utils'

{ commands
, hintCharHandler 
, findCharHandler
} = require 'commands'

{ getPref
, isCommandDisabled 
} = require 'prefs'


MODE_NORMAL = 1
MODE_HINTS  = 2
MODE_FIND   = 3

class Vim
  constructor: (@window) ->
    @mode     = MODE_NORMAL
    @keys     = []
    @markers  = undefined
    @cb       = undefined
    @findStr  = ""

  enterFindMode: ->
    @mode = MODE_FIND

  enterHintsMode: (@markers, @cb) ->
    @mode = MODE_HINTS

  enterNormalMode: ->
    @mode = MODE_NORMAL
    @markers = @cb = undefined

  handleKeyDown: (keyboardEvent, keyStr) ->
    if @mode == MODE_NORMAL || keyStr == 'Esc'
      result = maybeCommand @keys.concat([keyStr])
    else if !keyboardEvent.ctrlKey and !keyboardEvent.metaKey
      if @mode == MODE_HINTS
        hintChars = getPref('hint_chars').toLowerCase()
        result = hintChars.search(regexpEscape(keyStr)) > -1
      else if @mode == MODE_FIND
        result = true

    if result then @keys.push keyStr

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
      else if @mode == MODE_FIND
        findCharHandler @, lastKeyStr, keyboardEvent.charCode
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
