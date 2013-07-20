unload = do ->
  # Initialize the array of unloaders on the first usage
  unloaders = []

  return (callback, container) ->

    # Calling with no arguments runs all the unloader callbacks
    if !callback
      unloader() for unloader in unloaders
      unloaders.length = 0

    # The callback is bound to the lifetime of the container if we have one
    else if container
      # Remove the unloader when the container unloads
      container.addEventListener('unload', removeUnloader, false)

      # Wrap the callback to additionally remove the unload listener
      origCallback = callback
      callback = ->
        container.removeEventListener('unload', removeUnloader, false)
        origCallback()

    # Wrap the callback in a function that ignores failures
    unloader = -> try callback()
    unloaders.push(unloader)

    # Provide a way to remove the unloader
    removeUnloader = ->
      index = unloaders.indexOf(unloader)
      if index > -1
        unloaders.splice(index, 1)

    return removeUnloader

exports.unload = unload
