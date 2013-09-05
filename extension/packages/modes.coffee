utils = require 'utils'
hints = require 'hints'

mode_hints =
  enter: (vim, storage, [ callback ]) ->
    markers = hints.injectHints(vim.window.document)
    if markers.length == 0
      vim.enterNormalMode()
      return
    storage.markers = markers
    storage.callback = callback

  # Processes the char, updates and hides/shows markers
  handleKeyDown: (vim, storage, event, keyStr) ->
    { markers, callback } = storage

    switch keyStr
      when 'Space'
        @rotateOverlappingMarkers(markers, true)
      when 'Shift-Space'
        @rotateOverlappingMarkers(markers, false)

      when 'Backspace'
        for marker in markers
          marker.deleteHintChar(keyStr)

      else
        return false if keyStr not in utils.getHintChars()
        for marker in markers
          marker.matchHintChar(keyStr)

          if marker.isMatched()
            marker.reward() # Add element features to the bloom filter
            callback(marker)
            vim.enterNormalMode()
            break

    return true

  onEnterNormalMode: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.callback = undefined

  # Finds all stacks of markers that overlap each other (by using `getStackFor`) (#1), and rotates
  # their `z-index`:es (#2), thus alternating which markers are visible.
  rotateOverlappingMarkers: (originalMarkers, forward) ->
    # Shallow working copy. This is necessary since `markers` will be mutated and eventually empty.
    markers = originalMarkers[..]

    # (#1)
    stacks = (@getStackFor(markers.pop(), markers) while markers.length > 0)

    # (#2)
    # Stacks of length 1 don't participate in any overlapping, and can therefore be skipped.
    for stack in stacks when stack.length > 1
      # This sort is not required, but makes the rotation more predictable.
      stack.sort((a, b) -> a.markerElement.style.zIndex - b.markerElement.style.zIndex)

      # Array of z indices
      indexStack = (m.markerElement.style.zIndex for m in stack)
      # Shift the array of indices one item forward or back
      if forward
        indexStack.unshift(indexStack.pop())
      else
        indexStack.push(indexStack.shift())

      for marker, index in stack
        marker.markerElement.style.setProperty('z-index', indexStack[index], 'important')

    return

  # Get an array containing `marker` and all markers that overlap `marker`, if any, which is called a
  # "stack". All markers in the returned stack are spliced out from `markers`, thus mutating it.
  getStackFor: (marker, markers) ->
    stack = [marker]

    { top, bottom, left, right } = marker.position

    index = 0
    while index < markers.length
      nextMarker = markers[index]

      { top: nextTop, bottom: nextBottom, left: nextLeft, right: nextRight } = nextMarker.position
      overlapsVertically   = (nextBottom >= top  and nextTop  <= bottom)
      overlapsHorizontally = (nextRight  >= left and nextLeft <= right)

      if overlapsVertically and overlapsHorizontally
        # Also get all markers overlapping this one
        markers.splice(index, 1)
        stack = stack.concat(@getStackFor(nextMarker, markers))
      else
        # Continue the search
        index++

    return stack


modes =
  hints: mode_hints

exports.modes = modes
