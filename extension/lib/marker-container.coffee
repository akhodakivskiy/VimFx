###
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

# This file manages a collection of hint markers. This involves creating them,
# assigning hints to them and matching them against pressed keys.

huffman = require('n-ary-huffman')
Marker = require('./marker')

CONTAINER_ID = 'VimFxMarkersContainer'

# `z-index` can be infinite in theory, but not in practice. This is the largest
# value Firefox handles.
MAX_Z_INDEX = 2147483647

class MarkerContainer
  constructor: (options) ->
    {
      @window
      @getComplementaryWrappers
      hintChars
      @adjustZoom = true
    } = options

    [@primaryHintChars, @secondaryHintChars] = hintChars.split(' ')
    @alphabet = @primaryHintChars + @secondaryHintChars
    @numEnteredChars = 0

    @isComplementary = false
    @hasLookedForComplementaryWrappers = false

    @markers = []
    @markerMap = {}

    @container = @window.document.createElement('box')
    @container.id = CONTAINER_ID

  # This static method looks for an element with the container ID and removes
  # it. This is more fail-safe than `@container?.remove()`, because we might
  # loose the reference to the container. Then we’d end up with unremovable
  # hints on the screen (which has happened in the past).
  @remove: (window) ->
    window.document.getElementById(CONTAINER_ID)?.remove()

  remove: ->
    MarkerContainer.remove(@window)
    @container = null

  reset: ->
    @numEnteredChars = 0
    marker.reset() for marker in @markers when marker.hintIndex > 0
    @refreshComplementaryVisiblity()

  refreshComplementaryVisiblity: ->
    for marker in @markers
      marker.setVisibility(marker.isComplementary == @isComplementary)
    return

  # Create `Marker`s for every element (represented by a regular object of data
  # about the element—a “wrapper,” a stand-in for the real element, which is
  # only accessible in frame scripts) in `wrappers`, and insert them into
  # `@window`.
  injectHints: (wrappers, viewport, pass) ->
    isComplementary = (pass == 'complementary')
    combined = []
    markers = []
    markerMap = {}

    for wrapper in wrappers
      marker = new Marker(wrapper, @window.document, {isComplementary})
      if wrapper.parentIndex?
        combined.push(marker)
      else
        markers.push(marker)
      markerMap[wrapper.elementIndex] = marker

    # Both the `z-index` assignment and the Huffman algorithm below require the
    # markers to be sorted.
    markers.sort((a, b) -> a.weight - b.weight)

    # Each marker gets a unique `z-index`, so that it can be determined if a
    # marker overlaps another. More important markers (higher weight) should
    # have higher `z-index`, in order not to start out overlapped. Existing
    # markers should also have higher `z-index` than newer markers, which is why
    # we start out large and not at zero.
    zIndex =
      MAX_Z_INDEX - markers.length - combined.length - @markers.length + 1
    for marker in markers
      marker.markerElement.style.zIndex = zIndex
      zIndex += 1
      # Add `z-index` space for all the children of the marker.
      zIndex += marker.wrapper.numChildren if marker.wrapper.numChildren?

    prefixes = switch pass
      when 'first'
        @primaryHintChars
      when 'second'
        @primaryHintChars[@markers.length..] + @secondaryHintChars
      else
        @alphabet
    diff = @alphabet.length - prefixes.length
    paddedMarkers =
      if diff > 0
        # Dummy nodes with infinite weight are be guaranteed to be first-level
        # children of the Huffman tree. When there are less prefixes than
        # characters in the alphabet, adding a few such dummy nodes makes sure
        # that there is one child per prefix in the first level (discarding the
        # dummy children).
        markers.concat(Array(diff).fill({weight: Infinity}))
      else
        # Otherwise, nothing needs to be done. Simply use as many prefixes as
        # needed (and ignore any remaining ones).
        markers

    tree = huffman.createTree(paddedMarkers, @alphabet.length, {sorted: true})

    setHint = (marker, hint) -> marker.setHint(hint)
    index = 0
    for node in tree.children by -1 when node.weight != Infinity
      prefix = prefixes[index]
      if node instanceof huffman.BranchPoint
        node.assignCodeWords(@alphabet, setHint, prefix)
      else
        setHint(node, prefix)
      index += 1

    # Markers for links with the same href can be combined to use the same hint.
    # They should all have the same `z-index` (because they all have the same
    # combined weight), but in case any of them cover another they still get a
    # unique `z-index` (space for this was added above).
    for marker in combined
      parent = markerMap[marker.wrapper.parentIndex]
      parentZIndex = Number(parent.markerElement.style.zIndex)
      marker.markerElement.style.zIndex = parentZIndex
      parent.markerElement.style.zIndex = parentZIndex + 1
      marker.setHint(parent.hint)
    markers.push(combined...)

    zoom = 1
    if @adjustZoom
      {ZoomManager, gBrowser: {selectedBrowser: browser}} = @window
      # If “full zoom” is not used, it means that “Zoom text only” is enabled.
      # If so, that “zoom” does not need to be taken into account.
      # `.getCurrentMode()` is added by the “Default FullZoom Level” extension.
      if ZoomManager.getCurrentMode?(browser) ? ZoomManager.useFullZoom
        zoom = ZoomManager.getZoomForBrowser(browser)

    fragment = @window.document.createDocumentFragment()
    fragment.appendChild(marker.markerElement) for marker in markers
    @container.appendChild(fragment)

    # Must be done after the hints have been inserted into the DOM (see
    # `Marker::setPosition`).
    marker.setPosition(viewport, zoom) for marker in markers

    @markers.push(markers...)
    Object.assign(@markerMap, markerMap)

  toggleComplementary: ->
    if not @isComplementary and not @hasLookedForComplementaryWrappers
      @isComplementary = true
      @hasLookedForComplementaryWrappers = true
      @getComplementaryWrappers(({wrappers, viewport}) =>
        if wrappers.length > 0
          @injectHints(wrappers, viewport, 'complementary')
          if @isComplementary
            @reset()
          else
            @refreshComplementaryVisiblity()
        else
          @isComplementary = false
          @hasLookedForComplementaryWrappers = false
      )
    else
      @isComplementary = not @isComplementary
      @reset()

  matchHintChar: (char) ->
    matchedMarkers = []

    for marker in @markers
      if marker.isComplementary == @isComplementary and
         marker.hintIndex == @numEnteredChars
        matched = marker.matchHintChar(char)
        marker.hide() unless matched
        if marker.isMatched()
          marker.markMatched(true)
          matchedMarkers.push(marker)

    @numEnteredChars += 1
    return matchedMarkers

  deleteHintChar: ->
    for marker in @markers
      switch marker.hintIndex - @numEnteredChars
        when 0
          marker.deleteHintChar()
        when -1
          marker.show()
    @numEnteredChars -= 1 unless @numEnteredChars == 0


  rotateOverlapping: (forward) ->
    rotateOverlappingMarkers(@markers, forward)

# Finds all stacks of markers that overlap each other (by using `getStackFor`)
# (#1), and rotates their `z-index`:es (#2), thus alternating which markers are
# visible.
rotateOverlappingMarkers = (originalMarkers, forward) ->
  # `markers` will be mutated and eventually empty.
  markers = originalMarkers.filter((marker) -> marker.visible)

  # (#1)
  stacks = (getStackFor(markers.pop(), markers) while markers.length > 0)

  # (#2)
  # Stacks of length 1 don't participate in any overlapping, and can therefore
  # be skipped.
  for stack in stacks when stack.length > 1
    # This sort is not required, but makes the rotation more predictable.
    stack.sort((a, b) ->
      return a.markerElement.style.zIndex - b.markerElement.style.zIndex
    )

    zIndices = (marker.markerElement.style.zIndex for marker in stack)
    # Shift the `z-index`:es one item forward or back. The higher the `z-index`,
    # the more important the element. `forward` should give the next-most
    # important element the best `z-index` and so on.
    if forward
      zIndices.push(zIndices.shift())
    else
      zIndices.unshift(zIndices.pop())

    for marker, index in stack
      marker.markerElement.style.zIndex = zIndices[index]

  return

# Get an array containing `marker` and all markers that overlap `marker`, if
# any, which is called a "stack". All markers in the returned stack are spliced
# out from `markers`, thus mutating it.
getStackFor = (marker, markers) ->
  stack = [marker]

  {top, bottom, left, right} = marker.position

  index = 0
  while index < markers.length
    nextMarker = markers[index]

    next = nextMarker.position
    overlapsVertically   = (next.bottom >= top  and next.top  <= bottom)
    overlapsHorizontally = (next.right  >= left and next.left <= right)

    if overlapsVertically and overlapsHorizontally
      # Also get all markers overlapping this one.
      markers.splice(index, 1)
      stack = stack.concat(getStackFor(nextMarker, markers))
    else
      # Continue the search.
      index += 1

  return stack

module.exports = MarkerContainer
