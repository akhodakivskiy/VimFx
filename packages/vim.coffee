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

  keypress: (key) ->
    @keys.push key
    if command = _getCommand(@mode, @keys)
      command @
      @keys = []
      return key != 'Esc' 
    else if _maybeCommand(@mode, @keys) 
      return true
    else
      @keys.pop()
      return false

  enterHintsMode: () ->
    @mode = MODE_HINTS

  enterNormalMode: () ->
    @markers = @cb = undefined

    @mode = MODE_NORMAL

_endsWithEsc = (keys) ->
  return keys.join(',').match(/Esc$/)

_getCommand = (mode, keys) ->
  if mode == MODE_NORMAL or _endsWithEsc(keys)
    sequence = keys.join(',')
    if command = commands[sequence]
      return command
    else if keys.length > 0
      return _getCommand mode, keys.slice(1)

  else if mode == MODE_HINTS
    return (vim) =>
      char = keys[keys.length - 1].toLowerCase()
      return hintCharHandler(vim, char)

  return undefined

_maybeCommand = (mode, keys) ->
  if mode == MODE_NORMAL and keys.length > 0
    sequence = keys.join(',')
    for commandSequence in Object.keys(commands)
      if commandSequence.search(sequence) == 0
        return true

    return _maybeCommand mode, keys.slice(1)

  return false

exports.Vim = Vim
