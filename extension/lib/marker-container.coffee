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
utils = require('./utils')

CONTAINER_ID = 'VimFxMarkersContainer'

# `z-index` can be infinite in theory, but not in practice. This is the largest
# value Firefox handles.
MAX_Z_INDEX = 2147483647

SPACE = ' '

class MarkerContainer
  constructor: (options) ->
    {
      @window
      @getComplementaryWrappers
      hintChars
      @adjustZoom = true
      @minWeightDiff = 10 # Pixels of area.
    } = options

    [@primaryHintChars, @secondaryHintChars] = hintChars.split(' ')
    @alphabet = @primaryHintChars + @secondaryHintChars
    @enteredHint = ''
    @enteredText = ''

    @isComplementary = false
    @complementaryState = 'NOT_REQUESTED'

    @visualFeedbackUpdater = null

    @markers = []
    @markerMap = {}
    @highlightedMarkers = []

    @container = @window.document.createElement('box')
    @container.id = CONTAINER_ID
    if @alphabet not in [@alphabet.toLowerCase(), @alphabet.toUpperCase()]
      @container.classList.add('has-mixedcase')

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
    @enteredHint = ''
    @enteredText = ''
    @resetMarkers()

  resetMarkers: ->
    @resetHighlightedMarkers()
    for marker in @markers
      if marker.isComplementary == @isComplementary
        marker.reset()
        @updateHighlightedMarkers(marker)
      else
        marker.hide()
    @markHighlightedMarkers()

  resetHighlightedMarkers: ->
    marker.markHighlighted(false) for marker in @highlightedMarkers
    @highlightedMarkers = []

  markHighlightedMarkers: ->
    marker.markHighlighted(true) for marker in @highlightedMarkers
    return

  updateHighlightedMarkers: (marker) ->
    return unless marker.visible

    if @highlightedMarkers.length == 0
      @highlightedMarkers = [marker]
      return

    [firstHighlightedMarker] = @highlightedMarkers
    comparison = compareHints(marker, firstHighlightedMarker, @alphabet)

    if comparison == 0 and firstHighlightedMarker.visible
      @highlightedMarkers.push(marker)
      return

    if comparison < 0 or not firstHighlightedMarker.visible
      @highlightedMarkers = [marker]
      return

  createHuffmanTree: (markers, options = {}) ->
    return huffman.createTree(
      markers,
      @alphabet.length,
      Object.assign({
        compare: compareWeights.bind(null, @minWeightDiff)
      }, options)
    )

  # Create `Marker`s for every element (represented by a regular object of data
  # about the element—a “wrapper,” a stand-in for the real element, which is
  # only accessible in frame scripts) in `wrappers`, and insert them into
  # `@window`.
  injectHints: (wrappers, viewport, pass) ->
    markers = Array(wrappers.length)
    markerMap = {}

    zoom = 1
    if @adjustZoom
      {ZoomManager, gBrowser: {selectedBrowser: browser}} = @window
      # If “full zoom” is not used, it means that “Zoom text only” is enabled.
      # If so, that “zoom” does not need to be taken into account.
      # `.getCurrentMode()` is added by the “Default FullZoom Level” extension.
      if ZoomManager.getCurrentMode?(browser) ? ZoomManager.useFullZoom
        zoom = ZoomManager.getZoomForBrowser(browser)

    for wrapper, index in wrappers
      marker = new Marker({
        wrapper, document: @window.document, viewport, zoom
        isComplementary: (pass == 'complementary')
      })
      markers[index] = marker
      markerMap[wrapper.elementIndex] = marker
      if marker.isComplementary != @isComplementary or @enteredHint != ''
        marker.hide()

    nonCombinedMarkers =
      markers.filter((marker) -> not marker.wrapper.parentIndex?)
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
        # Dummy nodes with infinite weight are guaranteed to be first-level
        # children of the Huffman tree. When there are less prefixes than
        # characters in the alphabet, adding a few such dummy nodes makes sure
        # that there is one child per prefix in the first level (discarding the
        # dummy children).
        nonCombinedMarkers.concat(Array(diff).fill({weight: Infinity}))
      else
        # Otherwise, nothing needs to be done. Simply use as many prefixes as
        # needed (and ignore any remaining ones).
        nonCombinedMarkers

    tree = @createHuffmanTree(paddedMarkers)

    index = 0
    for node in tree.children by -1 when node.weight != Infinity
      prefix = prefixes[index]
      if node instanceof huffman.BranchPoint
        node.assignCodeWords(@alphabet, setHint, prefix)
      else
        setHint(node, prefix)
      index += 1

    # Each marker gets a unique `z-index`, so that it can be determined if a
    # marker overlaps another. Larger elements should have higher `z-index`,
    # because it looks odd when the hint for a smaller element overlaps the hint
    # for a larger element. Existing markers should also have higher `z-index`
    # than newer markers, which is why we start out large and not at zero.
    zIndex = MAX_Z_INDEX - markers.length - @markers.length + 1
    markers.sort((a, b) -> a.wrapper.shape.area - b.wrapper.shape.area)
    for marker in markers
      marker.markerElement.style.zIndex = zIndex
      zIndex += 1

      if marker.wrapper.parentIndex?
        parent = markerMap[marker.wrapper.parentIndex]
        marker.setHint(parent.hint)

      @updateHighlightedMarkers(marker)

    @markHighlightedMarkers()

    fragment = @window.document.createDocumentFragment()
    fragment.appendChild(marker.markerElement) for marker in markers
    @container.appendChild(fragment)

    # Must be done after the hints have been inserted into the DOM (see
    # `Marker::setPosition`).
    marker.setPosition() for marker in markers

    @markers.push(markers...)
    Object.assign(@markerMap, markerMap)

    if @enteredText != ''
      [matchingMarkers, nonMatchingMarkers] = @matchText(@enteredText)
      marker.hide() for marker in nonMatchingMarkers
      @setHintsForTextFilteredMarkers()
      @updateVisualFeedback(matchingMarkers)

  setHintsForTextFilteredMarkers: ->
    markers = []
    combined = []
    visibleParentMap = {}

    visibleMarkers = @markers.filter((marker) -> marker.visible)

    for marker in visibleMarkers
      wrappedMarker = wrapTextFilteredMarker(marker)
      {parentIndex} = marker.wrapper

      if parentIndex?
        parent = @markerMap[parentIndex]
        switch
          when parentIndex of visibleParentMap
            combined.push(wrappedMarker)
          when parent.visible
            visibleParentMap[parentIndex] = wrapTextFilteredMarker(parent)
            combined.push(wrappedMarker)
          else
            # If the parent isn’t visible, it’s because it didn’t match
            # `@enteredText`. If so, promote this marker as the parent.
            visibleParentMap[parentIndex] = wrappedMarker
            markers.push(wrappedMarker)
      else
        markers.push(wrappedMarker)

    # When creating hints after having filtered the markers by their text, it
    # makes sense to give the elements with the shortest text the best hints.
    # The idea is that the more of the element’s text is matched, the more
    # likely it is to be the intended target. However, using the (negative) area
    # as weight can result in really awful hints (such as “VVVS”) for larger
    # elements on crowded pages like Reddit and Hackernews, which just looks
    # broken. Instead this is achieved by using equal weight for all markers
    # (see `wrapTextFilteredMarker`) and sorting the markers by area (in
    # ascending order) beforehand.
    markers.sort((a, b) -> a.marker.text.length - b.marker.text.length)

    tree = @createHuffmanTree(markers, {sorted: true})
    tree.assignCodeWords(@alphabet, ({marker}, hint) -> marker.setHint(hint))

    for {marker} in combined
      {marker: parent} = visibleParentMap[marker.wrapper.parentIndex]
      marker.setHint(parent.hint)

    @resetHighlightedMarkers()
    for {marker} in markers.concat(combined)
      @updateHighlightedMarkers(marker)
      marker.refreshPosition()
    @markHighlightedMarkers()

    return

  toggleComplementary: ->
    if not @isComplementary and
       @complementaryState in ['NOT_REQUESTED', 'NOT_FOUND']
      @isComplementary = true
      @complementaryState = 'PENDING'
      @getComplementaryWrappers(({wrappers, viewport}) =>
        if wrappers.length > 0
          @complementaryState = 'FOUND'
          @enteredText = '' if @isComplementary
          @injectHints(wrappers, viewport, 'complementary')
          if @isComplementary
            @reset()
            @updateVisualFeedback([])
        else
          @isComplementary = false
          @complementaryState = 'NOT_FOUND'
      )

    else
      @isComplementary = not @isComplementary
      unless @complementaryState == 'PENDING'
        @reset()
        @updateVisualFeedback([])

  matchHint: (hint) ->
    matchingMarkers = []
    nonMatchingMarkers = []

    for marker in @markers when marker.visible
      if marker.matchHint(hint)
        matchingMarkers.push(marker)
      else
        nonMatchingMarkers.push(marker)

    return [matchingMarkers, nonMatchingMarkers]

  matchText: (text) ->
    matchingMarkers = []
    nonMatchingMarkers = []

    splitEnteredText = @splitEnteredText(text)
    for marker in @markers when marker.visible
      if marker.matchText(splitEnteredText)
        matchingMarkers.push(marker)
      else
        nonMatchingMarkers.push(marker)

    return [matchingMarkers, nonMatchingMarkers]

  splitEnteredText: (text = @enteredText) ->
    return text.trim().split(SPACE)

  isHintChar: (char) ->
    return (@enteredHint != '' or char in @alphabet)

  addChar: (char, isHintChar = null) ->
    @isComplementary = false if @complementaryState == 'PENDING'
    isHintChar ?= @isHintChar(char)
    hint = @enteredHint + char
    text = @enteredText + char.toLowerCase()

    if not isHintChar and char == SPACE
      matchingMarkers = @markers.filter((marker) -> marker.visible)
      unless @enteredText == '' or @enteredText.endsWith(SPACE)
        @enteredText = text
        @updateVisualFeedback(matchingMarkers)
      return matchingMarkers

    [matchingMarkers, nonMatchingMarkers] =
      if isHintChar
        @matchHint(hint)
      else
        @matchText(text)

    return nonMatchingMarkers if matchingMarkers.length == 0

    marker.hide() for marker in nonMatchingMarkers

    if isHintChar
      @enteredHint = hint
      @resetHighlightedMarkers()
      for marker in matchingMarkers
        marker.markMatchedPart(hint)
        @updateHighlightedMarkers(marker)
      @markHighlightedMarkers()
    else
      @enteredText = text
      @setHintsForTextFilteredMarkers() unless nonMatchingMarkers.length == 0

    @updateVisualFeedback(matchingMarkers)
    return matchingMarkers

  deleteChar: ->
    @isComplementary = false if @complementaryState == 'PENDING'
    return @deleteHintChar() or @deleteTextChar()

  deleteHintChar: ->
    return false if @enteredHint == ''
    hint = @enteredHint[...-1]
    matchingMarkers = []

    @resetHighlightedMarkers()
    splitEnteredText = @splitEnteredText()
    for marker in @markers when marker.isComplementary == @isComplementary
      marker.markMatchedPart(hint)
      if marker.matchHint(hint) and marker.matchText(splitEnteredText)
        marker.show()
        matchingMarkers.push(marker)
      @updateHighlightedMarkers(marker)
    @markHighlightedMarkers()

    @enteredHint = hint
    @updateVisualFeedback(matchingMarkers)
    return matchingMarkers

  deleteTextChar: ->
    return false if @enteredText == ''
    text = @enteredText[...-1]
    matchingMarkers = []

    if text == ''
      @resetMarkers()
      matchingMarkers = @markers.filter((marker) -> marker.visible)
    else
      splitEnteredText = @splitEnteredText(text)
      for marker in @markers when marker.isComplementary == @isComplementary
        if marker.matchText(splitEnteredText)
          marker.show()
          matchingMarkers.push(marker)
      @setHintsForTextFilteredMarkers()

    @enteredText = text
    @updateVisualFeedback(matchingMarkers)
    return matchingMarkers

  updateVisualFeedback: (matchingMarkers) ->
    @visualFeedbackUpdater?(this, matchingMarkers)

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

    [first, middle..., last] =
      (marker.markerElement.style.zIndex for marker in stack)

    # Shift the `z-index`:es one item forward or back. The higher the `z-index`,
    # the more important the element. `forward` should give the next-most
    # important element the best `z-index` and so on.
    zIndices =
      if forward
        [middle..., last, first]
      else
        [last, first, middle...]

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

setHint = (marker, hint) -> marker.setHint(hint)

wrapTextFilteredMarker = (marker) ->
  return {marker, weight: 1}

compareHints = (markerA, markerB, alphabet) ->
  lengthDiff = markerA.hint.length - markerB.hint.length
  return lengthDiff unless lengthDiff == 0

  return 0 if markerA.hint == markerB.hint

  scoresA = getHintCharScores(markerA.hint, alphabet)
  scoresB = getHintCharScores(markerB.hint, alphabet)

  sumA = utils.sum(scoresA)
  sumB = utils.sum(scoresB)
  sumDiff = sumA - sumB
  return sumDiff unless sumDiff == 0

  for scoreA, index in scoresA by -1
    scoreB = scoresB[index]
    scoreDiff = scoreA - scoreB
    return scoreDiff unless scoreDiff == 0

  return 0

getHintCharScores = (hint, alphabet) ->
  return hint.split('').map((char) -> alphabet.indexOf(char) + 1)

compareWeights = (minDiff, a, b) ->
  diff = a.weight - b.weight
  if a instanceof huffman.BranchPoint or b instanceof huffman.BranchPoint
    return diff
  else
    return switch
      when diff <= -minDiff
        -1
      when diff >= minDiff
        +1
      else
        0

module.exports = MarkerContainer
