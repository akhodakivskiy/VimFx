class Unloader
  constructor: ->
    @unloaders = []

  unload: ->
    unloader() for unloader in @unloaders
    @unloaders.length = 0

  add: (callback) ->
    # Wrap the callback in a function that ignores failures.
    unloader = -> try callback()
    @unloaders.push(unloader)

exports.unloader = new Unloader
