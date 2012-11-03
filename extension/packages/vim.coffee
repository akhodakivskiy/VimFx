{ getWindowId, Bucket } = require 'utils'

{ commands,
  hintCharHandler 
} = require 'commands'

MODE_NORMAL = 1
MODE_HINTS  = 2

class Vim
  constructor: (@window) ->
    @mode     = MODE_NORMAL
    @keys     = []
    @markers  = undefined
    @cb       = undefined

  pushKey: (keyStr) ->
    if _maybeCommand(@mode, @keys, keyStr)
      @keys.push keyStr
      return true

    return false

  execKeys: ->
    if command = _getCommand(@mode, @keys)
      lastKey = @keys[@keys.length - 1]
      command @
      @keys = []
      return lastKey != 'Esc' 

  enterHintsMode: () ->
    @mode = MODE_HINTS

  enterNormalMode: () ->
    @markers = @cb = undefined

    @mode = MODE_NORMAL

_getCommand = (mode, keys) ->
  lastKey = keys[keys.length - 1]

  if mode == MODE_NORMAL or lastKey == 'Esc'
    sequence = keys.join(',')
    if command = commands[sequence]
      return command
    else if keys.length > 0
      return _getCommand mode, keys.slice(1)

  else if mode == MODE_HINTS and keys.length > 0
    # `lastKey` should be one hint chars or `Backspace`
    hintChars = getPref('hint_chars').toLowerCase() + 'backspace'
    if hintChars.search(lastKey.toLowerCase()) > -1
      return (vim) =>
        return hintCharHandler(vim, lastKey.toLowerCase())

  return undefined

_maybeCommand = (mode, keys, keyStr) ->
    if mode == MODE_NORMAL || keyStr == 'Esc'
      sequence = keys.concat([keyStr]).join(',')
      for commandSequence in Object.keys(commands)
        if commandSequence.indexOf(sequence) == 0
          return true

      if keys.length > 0
        return _maybeCommand mode, keys.slice(1), keyStr

    else if mode == MODE_HINTS
      hintChars = getPref('hint_chars').toLowerCase()
      return (hintChars.search keyStr != -1)

    return false

exports.Vim = Vim
