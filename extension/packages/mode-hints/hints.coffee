utils                     = require 'utils'
{ getPref }               = require 'prefs'
{ Marker }                = require 'mode-hints/marker'
{ addHuffmanCodeWordsTo } = require 'mode-hints/huffman'

{ interfaces: Ci } = Components

HTMLDocument  = Ci.nsIDOMHTMLDocument
XULDocument   = Ci.nsIDOMXULDocument
FrameElement  = Ci.nsIDOMHTMLFrameElement
IFrameElement = Ci.nsIDOMHTMLIFrameElement

CONTAINER_ID  = 'VimFxHintMarkerContainer'
Z_INDEX_START = 2147480001 # The highest `z-index` used in style.css plus one.
# In theory, `z-index` can be infinitely large. In practice, Firefox uses a
# 32-bit signed integer to store it, so the maximum value is 2147483647
# (http://www.puidokas.com/max-z-index/). Youtube (insanely) uses 1999999999
# for its top bar. So by using 2147480001 as a base, we trump that value with
# lots of margin, still leaving a few thousand values for markers, which should
# be more than enough. Hopefully no sites are crazy enough to use even higher
# values.


removeHints = (document) ->
  document.getElementById(CONTAINER_ID)?.remove()


injectHints = (window) ->
  { document } = window

  { clientWidth, clientHeight } = document.documentElement
  viewport =
    left:    0
    top:     0
    right:   clientWidth
    bottom:  clientHeight
    width:   clientWidth
    height:  clientHeight
    scrollX: window.scrollX
    scrollY: window.scrollY
  markers = createMarkers(window, viewport)

  return if markers.length == 0

  for marker in markers
    marker.weight = marker.elementShape.area

  # Each marker gets a unique `z-index`, so that it can be determined if a marker overlaps another.
  # Put more important markers (higher weight) at the end, so that they get higher `z-index`, in
  # order not to be overlapped.
  markers.sort((a, b) -> a.weight - b.weight)
  for marker, index in markers
    marker.markerElement.style.setProperty('z-index', Z_INDEX_START + index, 'important')

  hintChars = utils.getHintChars()
  addHuffmanCodeWordsTo(markers, {alphabet: hintChars}, (marker, hint) -> marker.setHint(hint))

  removeHints(document)
  container = utils.createElement(document, 'div', {id: CONTAINER_ID})
  document.documentElement.appendChild(container)

  for marker in markers
    container.appendChild(marker.markerElement)
    # Must be done after the hints have been inserted into the DOM (see marker.coffee)
    marker.setPosition(viewport)

  return markers


createMarkers = (window, viewport, parents = []) ->
  { document } = window
  markers = []

  # For now we aren't able to handle hint markers in XUL Documents :(
  return [] unless document instanceof HTMLDocument # or document instanceof XULDocument

  candidates = utils.getMarkableElements(document, {type: 'all'})
  for element in candidates
    shape = getElementShape(window, element, viewport, parents)
    # If `element` has no visible shape then it shouldn’t get any marker.
    continue unless shape

    markers.push(new Marker(element, shape))

    if element instanceof FrameElement or element instanceof IFrameElement
      frame = element.contentWindow
      [ rect ] = shape.rects # Frames only have one rect.

      # Calculate the visible part of the frame, according to the parent.
      { clientWidth, clientHeight } = frame.document.documentElement
      frameViewport =
        left:   Math.max(viewport.left - rect.left, 0)
        top:    Math.max(viewport.top  - rect.top,  0)
        right:  clientWidth  + Math.min(viewport.right  - rect.right,  0)
        bottom: clientHeight + Math.min(viewport.bottom - rect.bottom, 0)

      computedStyle = window.getComputedStyle(frame.frameElement)
      offset =
        left: rect.left +
          parseFloat(computedStyle.getPropertyValue('border-left-width')) +
          parseFloat(computedStyle.getPropertyValue('padding-left'))
        top: rect.top +
          parseFloat(computedStyle.getPropertyValue('border-top-width')) +
          parseFloat(computedStyle.getPropertyValue('padding-top'))

      frameMarkers = createMarkers(frame, frameViewport, parents.concat({ window, offset }))
      markers.push(frameMarkers...)

  return markers

# Returns the “shape” of `element`:
#
# - `rects`: Its `.getClientRects()` rectangles.
# - `visibleRects`: The parts of rectangles out of the above that are inside
#   `viewport`.
# - `nonCoveredPoint`: The coordinates of the first point of `element` that
#   isn’t covered by another element (except children of `element`).
# - `area`: The area of the part of `element` that is inside `viewport`.
#
# Returns `null` if `element` is outside `viewport` or entirely covered by
# other elements.
getElementShape = (window, element, viewport, parents) ->
  # `element.getClientRects()` returns a list of rectangles, usually just one,
  # which is identical to the one returned by
  # `element.getBoundingClientRect()`. However, if `element` is inline and
  # line-wrapped, then it returns one rectangle for each line, since each line
  # may be of different length, for example. That allows us to properly add
  # hints to line-wrapped links.
  rects = element.getClientRects()
  totalArea = 0
  visibleRects = []
  for rect in rects when isInsideViewport(rect, viewport)
    visibleRect = adjustRectToViewport(rect, viewport)
    totalArea += visibleRect.area
    visibleRects.push(visibleRect)

  return null if visibleRects.length == 0

  # If `element` has no area there is nothing to click, unless `element` has
  # only one visible rect and either a width or a height. That means that
  # everything inside `element` is floated and/or absolutely positioned (and
  # that `element` hasn’t been made to “contain” the floats). For example, a
  # link in a menu could contain a span of text floated to the left and an icon
  # floated to the right. Those are still clickable. Therefore we return the
  # shape of the first visible child instead. At least in that example, that’s
  # the best bet.
  if totalArea == 0 and visibleRects.length == 1
    [ rect ] = visibleRects
    if rect.width > 0 or rect.height > 0
      for child in element.children
        shape = getElementShape(window, child, viewport, parents)
        return shape if shape
      return null

  return null if totalArea == 0

  # Even if `element` has a visible rect, it might be covered by other elements.
  for visibleRect in visibleRects
    nonCoveredPoint = getFirstNonCoveredPoint(window, element, visibleRect, parents)
    break if nonCoveredPoint

  return null unless nonCoveredPoint

  return {
    rects, visibleRects, nonCoveredPoint, area: totalArea
  }


MINIMUM_EDGE_DISTANCE = 4
isInsideViewport = (rect, viewport) ->
  return \
    rect.left   <= viewport.right  - MINIMUM_EDGE_DISTANCE and
    rect.top    <= viewport.bottom + MINIMUM_EDGE_DISTANCE and
    rect.right  >= viewport.left   + MINIMUM_EDGE_DISTANCE and
    rect.bottom >= viewport.top    - MINIMUM_EDGE_DISTANCE


adjustRectToViewport = (rect, viewport) ->
  left   = Math.max(rect.left,   viewport.left)
  right  = Math.min(rect.right,  viewport.right)
  top    = Math.max(rect.top,    viewport.top)
  bottom = Math.min(rect.bottom, viewport.bottom)

  width  = right - left
  height = bottom - top
  area   = width * height

  return {
    left, right, top, bottom
    height, width, area
  }


getFirstNonCoveredPoint = (window, element, elementRect, parents) ->
  # Determining if `element` is covered by other elements is a bit tricky.  We
  # use `document.elementFromPoint()` to check if `element`, or a child of
  # `element` (anything inside an `<a>` is clickable too), really is present in
  # `elementRect`. If so, we prepare that point for being returned (#A).
  #
  # However, if we’re currently in a frame, there might be something on top of
  # the frame that covers `element`. Therefore we check that the frame really
  # is present at the point for each parent in `parents`. (#B)
  #
  # If `element` still isn’t determined to be covered, we return the point. (#C)
  #
  # We start by checking the top-left corner, since that’s where we want to
  # place the marker, if possible. If there’s something else there, we check if
  # that element is not as wide as `element`. If so we recurse, checking the
  # point directly to the right of the found element. (#D)
  #
  # If that doesn’t find some exposed space of `element` we do the same
  # procedure again, but downwards instead. (#E)
  #
  # Otherwise `element` seems to be covered to the right of `x` and below `y`.
  # (#F)
  #
  # But before we start we need to hack around a little problem. If `element`
  # has `border-radius`, the top-left corner won’t really belong to `element`,
  # so `document.elementFromPoint()` will return whatever is behind. The
  # solution is to temporarily add a CSS class that removes `border-radius`.
  element.classList.add('VimFxNoBorderRadius')

  triedElements = new Set()

  nonCoveredPoint = do recurse = (x = elementRect.left, y = elementRect.top) ->
    # (#A)
    elementAtPoint = window.document.elementFromPoint(x, y)
    if element.contains(elementAtPoint) # Note that `a.contains(a) == true`!
      covered = false
      point = {x, y}

      # (#B)
      currentWindow = window
      for {window: parentWindow, offset} in parents by -1
        point.x += offset.left
        point.y += offset.top
        elementAtPoint = parentWindow.document.elementFromPoint(point.x, point.y)
        if elementAtPoint != currentWindow.frameElement
          covered = true
          adjustment =
            x: point.x - x
            y: point.y - y
          break
        currentWindow = parentWindow

      # (#C)
      return point unless covered

    # `document.elementFromPoint()` returns `null` if the point is outside the
    # viewport. That should never happen, but in case it does we return.
    return false if elementAtPoint == null

    # If we have already looked around the found element, it is a waste of time
    # to do it again.
    return false if triedElements.has(elementAtPoint)
    triedElements.add(elementAtPoint)

    { right, bottom } = elementAtPoint.getBoundingClientRect()
    if adjustment
      right  -= adjustment.x
      bottom -= adjustment.y

    # (#B)
    if right < elementRect.right
      return point if point = recurse(right + 1, y)

    # (#C)
    if bottom < elementRect.bottom
      return point if point = recurse(x, bottom + 1)

    # (#D)
    return false

  element.classList.remove('VimFxNoBorderRadius')

  return nonCoveredPoint


# Finds all stacks of markers that overlap each other (by using `getStackFor`) (#1), and rotates
# their `z-index`:es (#2), thus alternating which markers are visible.
rotateOverlappingMarkers = (originalMarkers, forward) ->
  # Shallow working copy. This is necessary since `markers` will be mutated and eventually empty.
  markers = originalMarkers[..]

  # (#1)
  stacks = (getStackFor(markers.pop(), markers) while markers.length > 0)

  # (#2)
  # Stacks of length 1 don't participate in any overlapping, and can therefore be skipped.
  for stack in stacks when stack.length > 1
    # This sort is not required, but makes the rotation more predictable.
    stack.sort((a, b) -> a.markerElement.style.zIndex - b.markerElement.style.zIndex)

    # Array of z-indices
    indexStack = (marker.markerElement.style.zIndex for marker in stack)
    # Shift the array of indices one item forward or back
    if forward
      indexStack.unshift(indexStack.pop())
    else
      indexStack.push(indexStack.shift())

    for marker, index in stack
      marker.markerElement.style.setProperty('z-index', indexStack[index], 'important')

  return

# Get an array containing `marker` and all markers that overlap `marker`, if any, which is called
# a "stack". All markers in the returned stack are spliced out from `markers`, thus mutating it.
getStackFor = (marker, markers) ->
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
      stack = stack.concat(getStackFor(nextMarker, markers))
    else
      # Continue the search
      index++

  return stack


exports.injectHints = injectHints
exports.removeHints = removeHints
exports.rotateOverlappingMarkers = rotateOverlappingMarkers
