{ getCommand, maybeCommand }    = require 'commands'
{ getWindowId }                 = require 'utils'

MODE_NORMAL = 1


class Vim
  constructor: (@window) ->
    @mode = MODE_NORMAL
    @keys = []

  keypress: (keyInfo) ->
    @keys.push keyInfo
    if command = getCommand @keys
      command @window
      @keys = []
      true
    else if maybeCommand @keys
      true
    else
      false

  focus: (element) ->
    @activeElement = element
    console.log 'focus', @activeElement

  blur: (element) ->
    console.log 'blur', @activeElement
    delete @activeElement if @activeElement == element


  

class VimBucket
  constructor: ->
    @vims = {}
  
  get: (window) ->
    id = getWindowId window
    @vims[id] or @vims[id] = new Vim window

  forget: (window) ->
    id = getWindowId window
    delete @vims[id] if id

exports.VimBucket = VimBucket
