###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014, 2015.
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

# This file contains functions for getting markable elements, and related data,
# as well as for creating and inserting markers for markable elements.

huffman  = require('n-ary-huffman')
{Marker} = require('./marker')
utils    = require('./utils')

CONTAINER_ID = 'VimFxMarkersContainer'

Element     = Ci.nsIDOMElement
XULDocument = Ci.nsIDOMXULDocument

# For some time we used to return the hints container from `injectHints`, and
# use that reference to remove the hints when needed. That’s fine in theory, but
# in case anything breaks we might loose that reference and end up with
# unremovable hints on the screen. Explicitly looking for an element with the
# container ID is more fail-safe.
removeHints = (window) ->
  window.document.getElementById(CONTAINER_ID)?.remove()

# Create `Marker`s for every element (represented by a regular object of data
# about the element—a “wrapper,” a stand-in for the real element, which is only
# accessible in frame scripts) in `wrappers`, and insert them into `window`.
injectHints = (window, wrappers, viewport, options) ->
  semantic   = []
  unsemantic = []
  combined   = []
  markerMap  = {}

  for wrapper in wrappers
    marker = new Marker(wrapper, window.document)
    group = switch
      when wrapper.parentIndex? then combined
      when wrapper.semantic     then semantic
      else unsemantic
    group.push(marker)
    markerMap[wrapper.elementIndex] = marker

  markers = semantic.concat(unsemantic)

  return null if markers.length == 0

  # Each marker gets a unique `z-index`, so that it can be determined if a
  # marker overlaps another. Put more important markers (higher weight) at the
  # end, so that they get higher `z-index`, in order not to be overlapped.
  zIndex = 0
  setZIndexes = (markers) ->
    markers.sort((a, b) -> a.weight - b.weight)
    for marker in markers when marker not instanceof huffman.BranchPoint
      marker.markerElement.style.zIndex = zIndex++
      # Add `z-index` space for all the children of the marker.
      zIndex += marker.wrapper.numChildren if marker.wrapper.numChildren?
    return

  # The `markers` passed to this function have been sorted by `setZIndexes` in
  # advance, so we can skip sorting in the `huffman.createTree` function.
  hintChars = options.hint_chars
  createHuffmanTree = (markers) ->
    return huffman.createTree(markers, hintChars.length, {sorted: true})

  # Semantic elements should always get better hints and higher `z-index`:es
  # than unsemantic ones, even if they are smaller. The former is achieved by
  # putting the unsemantic elements in their own branch of the huffman tree.
  if unsemantic.length > 0
    if markers.length > hintChars.length
      setZIndexes(unsemantic)
      subTree = createHuffmanTree(unsemantic)
      semantic.push(subTree)
    else
      semantic.push(unsemantic...)

  setZIndexes(semantic)

  tree = createHuffmanTree(semantic)
  tree.assignCodeWords(hintChars, (marker, hint) -> marker.setHint(hint))

  # Markers for links with the same href can be combined to use the same hint.
  # They should all have the same `z-index` (because they all have the same
  # combined weight), but in case any of them cover another they still get a
  # unique `z-index` (space for this was added in `setZIndexes`).
  for marker in combined
    parent = markerMap[marker.wrapper.parentIndex]
    marker.markerElement.style.zIndex = parent.markerElement.style.zIndex++
    marker.setHint(parent.hint)
  markers.push(combined...)

  removeHints(window) # Better safe than sorry.
  container = window.document.createElement('box')
  container.id = CONTAINER_ID

  zoom = 1

  if options.ui
    container.classList.add('ui')
    window.document.getElementById('browser-panel').appendChild(container)
  else
    window.gBrowser.mCurrentBrowser.parentNode.appendChild(container)
    # If “full zoom” is not used, it means that “Zoom text only” is enabled.
    # If so, that “zoom” does not need to be taken into account.
    if window.ZoomManager.useFullZoom
      zoom =
        window.ZoomManager.getZoomForBrowser(window.gBrowser.selectedBrowser)

  for marker in markers
    container.appendChild(marker.markerElement)
    # Must be done after the hints have been inserted into the DOM (see
    # marker.coffee).
    marker.setPosition(viewport, zoom)

  return markers


getMarkableElementsAndViewport = (window, filter) ->
  {
    clientWidth, clientHeight # Viewport size excluding scrollbars, usually.
    scrollWidth, scrollHeight
  } = window.document.documentElement
  {innerWidth, innerHeight} = window # Viewport size including scrollbars.
  # We don’t want markers to cover the scrollbars, so we should use
  # `clientWidth` and `clientHeight`. However, when there are no scrollbars
  # those might be too small. Then we use `innerWidth` and `innerHeight`.
  width  = if scrollWidth  > innerWidth  then clientWidth  else innerWidth
  height = if scrollHeight > innerHeight then clientHeight else innerHeight
  viewport = {
    left:   0
    top:    0
    right:  width
    bottom: height
    width
    height
  }

  wrappers = []
  getMarkableElements(window, viewport, wrappers, filter)
  return {wrappers, viewport}

# `filter` is a function that is given every element in every frame of the page.
# It should return wrapper objects for markable elements and a falsy value for
# all other elements. All returned wrappers are added to `wrappers`. `wrappers`
# is modified instead of using return values to avoid array concatenation for
# each frame. It might sound expensive to go through _every_ element, but that’s
# actually what other methods like using XPath or CSS selectors would need to do
# anyway behind the scenes.
getMarkableElements = (window, viewport, wrappers, filter, parents = []) ->
  {document} = window

  for element in getAllElements(document) when element instanceof Element
    # `getRects` is fast and filters out most elements, so run it first of all.
    rects = getRects(element, viewport)
    continue unless rects.length > 0
    continue unless wrapper = filter(
      element, (elementArg) ->
        return getElementShape(window, viewport, parents, elementArg,
                               if elementArg == element then rects else null)
    )
    wrappers.push(wrapper)

  for frame in window.frames when frame.frameElement
    rect = frame.frameElement.getBoundingClientRect() # Frames only have one.
    continue unless isInsideViewport(rect, viewport)

    # Calculate the visible part of the frame, according to the parent.
    {clientWidth, clientHeight} = frame.document.documentElement
    frameViewport =
      left:   Math.max(viewport.left - rect.left, 0)
      top:    Math.max(viewport.top  - rect.top,  0)
      right:  clientWidth  + Math.min(viewport.right  - rect.right,  0)
      bottom: clientHeight + Math.min(viewport.bottom - rect.bottom, 0)

    # `.getComputedStyle()` may return `null` if the computed style isn’t
    # availble yet. If so, consider the element not visible.
    continue unless computedStyle = window.getComputedStyle(frame.frameElement)
    offset =
      left: rect.left +
        parseFloat(computedStyle.getPropertyValue('border-left-width')) +
        parseFloat(computedStyle.getPropertyValue('padding-left'))
      top: rect.top +
        parseFloat(computedStyle.getPropertyValue('border-top-width')) +
        parseFloat(computedStyle.getPropertyValue('padding-top'))

    getMarkableElements(frame, frameViewport, wrappers, filter,
                        parents.concat({window, offset}))

  return

getAllElements = (document) ->
  unless document instanceof XULDocument
    return document.getElementsByTagName('*')

  # Use a `Set` since this algorithm may find the same element more than once.
  # Ideally we should find a way to find all elements without duplicates.
  elements = new Set()
  getAllRegular = (element) ->
    # The first time `zF` is run `.getElementsByTagName('*')` may oddly include
    # `undefined` in its result! Filter those out.
    for child in element.getElementsByTagName('*') when child
      elements.add(child)
      getAllAnonymous(child)
    return
  getAllAnonymous = (element) ->
    for child in document.getAnonymousNodes(element) or []
      continue unless child instanceof Element
      elements.add(child)
      getAllRegular(child)
    return
  getAllRegular(document.documentElement)
  return Array.from(elements)

getRects = (element, viewport) ->
  # `element.getClientRects()` returns a list of rectangles, usually just one,
  # which is identical to the one returned by `element.getBoundingClientRect()`.
  # However, if `element` is inline and line-wrapped, then it returns one
  # rectangle for each line, since each line may be of different length, for
  # example. That allows us to properly add hints to line-wrapped links.
  return Array.filter(
    element.getClientRects(), (rect) -> isInsideViewport(viewport, rect)
  )

# Returns the “shape” of `element`:
#
# - `nonCoveredPoint`: The coordinates of the first point of `element` that
#   isn’t covered by another element (except children of `element`). It also
#   contains the offset needed to make those coordinates relative to the top
#   frame, as well as the rectangle that the coordinates occur in.
# - `area`: The area of the part of `element` that is inside `viewport`.
#
# Returns `null` if `element` is outside `viewport` or entirely covered by other
# elements.
getElementShape = (window, viewport, parents, element, rects = null) ->
  rects ?= getRects(element, viewport)
  totalArea = 0
  visibleRects = []
  for rect in rects
    visibleRect = adjustRectToViewport(rect, viewport)
    continue if visibleRect.area == 0
    totalArea += visibleRect.area
    visibleRects.push(visibleRect)

  if visibleRects.length == 0
    if rects.length == 1 and totalArea == 0
      [rect] = rects
      if rect.width > 0 or rect.height > 0
        # If we get here, it means that everything inside `element` is floated
        # and/or absolutely positioned (and that `element` hasn’t been made to
        # “contain” the floats). For example, a link in a menu could contain a
        # span of text floated to the left and an icon floated to the right.
        # Those are still clickable. Therefore we return the shape of the first
        # visible child instead. At least in that example, that’s the best bet.
        for child in element.children
          shape = getElementShape(window, viewport, parents, child)
          return shape if shape
    return null

  # Even if `element` has a visible rect, it might be covered by other elements.
  for visibleRect in visibleRects
    nonCoveredPoint = getFirstNonCoveredPoint(window, viewport, element,
                                              visibleRect, parents)
    if nonCoveredPoint
      nonCoveredPoint.rect = visibleRect
      break

  return null unless nonCoveredPoint

  return {
    nonCoveredPoint, area: totalArea
  }


MINIMUM_EDGE_DISTANCE = 4
isInsideViewport = (rect, viewport) ->
  return \
    rect.left   <= viewport.right  - MINIMUM_EDGE_DISTANCE and
    rect.top    <= viewport.bottom + MINIMUM_EDGE_DISTANCE and
    rect.right  >= viewport.left   + MINIMUM_EDGE_DISTANCE and
    rect.bottom >= viewport.top    - MINIMUM_EDGE_DISTANCE


adjustRectToViewport = (rect, viewport) ->
  # The right and bottom values are subtracted by 1 because
  # `document.elementFromPoint(right, bottom)` does not return the element
  # otherwise.
  left   = Math.max(rect.left,       viewport.left)
  right  = Math.min(rect.right - 1,  viewport.right)
  top    = Math.max(rect.top,        viewport.top)
  bottom = Math.min(rect.bottom - 1, viewport.bottom)

  # Make sure that `right >= left and bottom >= top`, since we subtracted by 1
  # above.
  right  = Math.max(right, left)
  bottom = Math.max(bottom, top)

  width  = right - left
  height = bottom - top
  area   = Math.floor(width * height)

  return {
    left, right, top, bottom
    height, width, area
  }


getFirstNonCoveredPoint = (window, viewport, element, elementRect, parents) ->
  # Tries a point `(x + dx, y + dy)`. Returns `(x, y)` (and the frame offset)
  # if it passes the tests. Otherwise it tries to the right of whatever is at
  # `(x, y)`, `tryRight` times . If nothing succeeds, `false` is returned. `dx`
  # and `dy` are used to offset the wanted point `(x, y)` while trying (see the
  # invocations of `tryPoint` below).
  tryPoint = (x, dx, y, dy, tryRight = 0) ->
    elementAtPoint = window.document.elementFromPoint(x + dx, y + dy)
    offset = {left: 0, top: 0}
    found = false

    # Ensure that `element`, or a child of `element` (anything inside an `<a>`
    # is clickable too), really is present at (x,y). Note that this is not 100%
    # bullet proof: Combinations of CSS can cause this check to fail, even
    # though `element` isn’t covered. We don’t try to temporarily reset such CSS
    # because of performance. Instead we rely on that some of the attempts below
    # will work. Note that `a.contains(a) == true`!
    if normalize(element).contains(elementAtPoint)
      found = true
      # If we’re currently in a frame, there might be something on top of the
      # frame that covers `element`. Therefore we ensure that the frame really
      # is present at the point for each parent in `parents`.
      currentWindow = window
      for parent in parents by -1
        offset.left += parent.offset.left
        offset.top  += parent.offset.top
        elementAtPoint = parent.window.document.elementFromPoint(
          offset.left + x + dx, offset.top + y + dy
        )
        unless frameAtPoint(currentWindow.frameElement, elementAtPoint)
          found = false
          break
        currentWindow = parent.window

    if found
      return {x, y, offset}
    else
      return false if elementAtPoint == null or tryRight == 0
      rect = elementAtPoint.getBoundingClientRect()
      x = rect.right - offset.left + 1
      return false if x > viewport.right
      return tryPoint(x, 0, y, 0, tryRight - 1)


  # Try the left-middle point, or immediately to the right of a covering element
  # at that point. If both of those are covered the whole element is considered
  # to be covered. The reasoning is:
  #
  # - A marker should show up as near the left edge of its visible area as
  #   possible. Having it appear to the far right (for example) is confusing.
  # - We can’t try too many times because of performance.
  # - We used to try left-top first, but if `element` has `border-radius`, the
  #   corners won’t really belong to `element`, so `document.elementFromPoint()`
  #   will return whatever is behind. This will result in missing or
  #   out-of-place markers. The solution is to temporarily add a CSS class that
  #   removes `border-radius`, but that turned out to be rather slow, making it
  #   not worth it. Usually you don’t see the difference between left-top and
  #   left-middle, because links are usually not that high.
  # - We used to try left-bottom as well, but that is so rare that it’s not
  #   worth it.
  #
  # It is safer to try points at least one pixel into the element from the
  # edges, hence the `+1`.
  {left, top, bottom, height} = elementRect
  nonCoveredPoint = tryPoint(left, +1, Math.floor(top + height / 2), 0, 1)

  return nonCoveredPoint

# In XUL documents there are “anonymous” elements. These are never returned by
# `document.elementFromPoint` but their closest non-anonymous parents are.
normalize = (element) ->
  return element.ownerDocument.getBindingParent(element) or element

# Returns whether `frameElement` corresponds to `elementAtPoint`. This is only
# complicated for the dev tools’ frame. `.elementAtPoint()` returns
# `<tabbrowser#content>` instead of the `<iframe>`. The dev tools might be in
# another tab and thus invisible, but `<tabbrowser#content>` is the same and
# visible in _all_ tabs, so we have to check that the frame really belongs to
# the current tab.
frameAtPoint = (frameElement, elementAtPoint) ->
  frame = normalize(frameElement)
  return false unless elementAtPoint == frame
  return true  unless frame.nodeName == 'tabbrowser' and frame.id == 'content'
  {gBrowser} = frameElement.ownerGlobal.top
  tabpanel = gBrowser.getNotificationBox(gBrowser.selectedBrowser)
  return tabpanel.contains(frameElement)

module.exports = {
  removeHints
  injectHints
  getMarkableElementsAndViewport
}
