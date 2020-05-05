# This file contains functions for getting markable elements and related data.

utils = require('./utils')
viewportUtils = require('./viewport')

{devtools} = Cu.import('resource://devtools/shared/Loader.jsm', {})

_Element = Ci.nsIDOMElement
if _Element
  isElementInstance = (el) -> el instanceof _Element
else
  Cu.importGlobalProperties(['Element'])
  isElementInstance = (el) -> Element.isInstance(el)

MIN_TEXTNODE_SIZE = 4

find = (window, filter, selector = '*') ->
  viewport = viewportUtils.getWindowViewport(window)
  wrappers = []
  getMarkableElements(window, viewport, wrappers, filter, selector)
  return wrappers

# `filter` is a function that is given every element in every frame of the page.
# It should return wrapper objects for markable elements and a falsy value for
# all other elements. All returned wrappers are added to `wrappers`. `wrappers`
# is modified instead of using return values to avoid array concatenation for
# each frame. It might sound expensive to go through _every_ element, but that’s
# actually what other methods like using XPath or CSS selectors would need to do
# anyway behind the scenes. However, it is possible to pass in a CSS selector,
# which allows getting markable elements in several passes with different sets
# of candidates.
getMarkableElements = (
  window, viewport, wrappers, filter, selector, parents = []
) ->
  {document} = window

  for element in getAllElements(document, selector)
    continue unless isElementInstance(element)
    # `getRects` is fast and filters out most elements, so run it first of all.
    rects = getRects(element, viewport)
    continue unless rects.insideViewport.length > 0
    continue unless wrapper = filter(
      element, (elementArg, tryRight = 1) ->
        return getElementShape(
          {window, viewport, parents, element: elementArg}, tryRight,
          if elementArg == element then rects else null
        )
    )
    wrappers.push(wrapper)

  # Note: with fission's out-of-process iframes, accessing frameElement might
  # result in a SecurityError. In this case, squelch it and don't drill down.
  for frame in window.frames when (try frame.frameElement)
    continue unless result = viewportUtils.getFrameViewport(
      frame.frameElement, viewport
    )
    {viewport: frameViewport, offset} = result
    getMarkableElements(
      frame, frameViewport, wrappers, filter, selector,
      parents.concat({window, offset})
    )

  return

findAllDOMs = (dom) ->
  return [dom].concat(
    Array.from(dom.querySelectorAll('*'))
      .filter((e) -> e.shadowRoot?)
      .map((e) -> findAllDOMs(e.shadowRoot))...
  )

getAllElements = (document, selector) ->
  return [].concat(
    findAllDOMs(document).map((d) ->
      Array.from(d.querySelectorAll(selector))
    )...
  )

getRects = (element, viewport) ->
  # `element.getClientRects()` returns a list of rectangles, usually just one,
  # which is identical to the one returned by `element.getBoundingClientRect()`.
  # However, if `element` is inline and line-wrapped, then it returns one
  # rectangle for each line, since each line may be of different length, for
  # example. That allows us to properly add hints to line-wrapped links.
  rects = element.getClientRects?() or []
  return {
    all: rects,
    insideViewport: Array.prototype.filter.call(
      rects,
      (rect) -> viewportUtils.isInsideViewport(rect, viewport)
    )
  }

# Returns the “shape” of an element:
#
# - `nonCoveredPoint`: The coordinates of the first point of the element that
#   isn’t covered by another element (except children of the element). It also
#   contains the offset needed to make those coordinates relative to the top
#   frame, as well as the rectangle that the coordinates occur in. It is `null`
#   if the element is outside `viewport` or entirely covered by other elements.
# - `area`: The area of the part of the element that is inside the viewport.
# - `width`: The width of the visible rect at `nonCoveredPoint`.
# - `textOffset`: The distance between the left edge of the element and the left
#   edge of its text vertically near `nonCoveredPoint`. Might be `null`. The
#   calculation might stop early if `isBlock`.
# - `isBlock`: `true` if the element is a block and has several lines of text
#   (which is the case for “cards” with an image to the left and a title as well
#   as some text to the right (where the entire “card” is a link)). This is used
#   to place the the marker at the edge of the block.
getElementShape = (elementData, tryRight, rects = null) ->
  {viewport, element} = elementData
  result =
    {nonCoveredPoint: null, area: 0, width: 0, textOffset: null, isBlock: false}

  rects ?= getRects(element, viewport)
  totalArea = 0
  visibleRects = []
  for rect, index in rects.insideViewport
    visibleRect = viewportUtils.adjustRectToViewport(rect, viewport)
    continue if visibleRect.area == 0
    visibleRect.index = index
    totalArea += visibleRect.area
    visibleRects.push(visibleRect)

  if visibleRects.length == 0
    if rects.all.length == 1 and totalArea == 0
      [rect] = rects.all
      if rect.width > 0 or rect.height > 0
        # If we get here, it means that everything inside `element` is floated
        # and/or absolutely positioned (and that `element` hasn’t been made to
        # “contain” the floats). For example, a link in a menu could contain a
        # span of text floated to the left and an icon floated to the right.
        # Those are still clickable. Therefore we return the shape of the first
        # visible child instead. At least in that example, that’s the best bet.
        for child in element.children
          childData = Object.assign({}, elementData, {element: child})
          shape = getElementShape(childData, tryRight)
          return shape if shape
    return result

  result.area = totalArea

  # Even if `element` has a visible rect, it might be covered by other elements.
  nonCoveredPoint = null
  nonCoveredPointRect = null
  for visibleRect in visibleRects
    nonCoveredPoint = getFirstNonCoveredPoint(
      elementData, visibleRect, tryRight
    )
    if nonCoveredPoint
      nonCoveredPointRect = visibleRect
      break

  return result unless nonCoveredPoint
  result.nonCoveredPoint = nonCoveredPoint

  result.width = nonCoveredPointRect.width

  lefts = []
  smallestBottom = Infinity
  hasSingleRect = (rects.all.length == 1)

  utils.walkTextNodes(element, (node) ->
    unless node.data.trim() == ''
      for quads in node.getBoxQuads()
        bounds = quads.getBounds()
        if bounds.width < MIN_TEXTNODE_SIZE or bounds.height < MIN_TEXTNODE_SIZE
          continue

        if utils.overlaps(bounds, nonCoveredPointRect)
          lefts.push(bounds.left)

        if hasSingleRect
          # The element is likely a block and has several lines of text; ignore
          # the `textOffset` (see the description of `textOffset` at the
          # beginning of the function).
          if bounds.top > smallestBottom
            result.isBlock = true
            return true

          if bounds.bottom < smallestBottom
            smallestBottom = bounds.bottom

    return false
  )

  if lefts.length > 0
    result.textOffset =
      Math.round(Math.min(lefts...) - nonCoveredPointRect.left)

  return result

getFirstNonCoveredPoint = (elementData, elementRect, tryRight) ->
  # Try the left-middle point, or immediately to the right of a covering element
  # at that point (when `tryRight == 1`). If both of those are covered the whole
  # element is considered to be covered. The reasoning is:
  #
  # - A marker should show up as near the left edge of its visible area as
  #   possible. Having it appear to the far right (for example) is confusing.
  # - We can’t try too many times because of performance.
  # - We used to try left-top first, but if the element has `border-radius`, the
  #   corners won’t belong to the element, so `document.elementFromPoint()` will
  #   return whatever is behind. One _could_ temporarily add a CSS class that
  #   removes `border-radius`, but that turned out to be too slow. Trying
  #   left-middle instead avoids the problem, and looks quite nice, actually.
  # - We used to try left-bottom as well, but that is so rare that it’s not
  #   worth it.
  #
  # It is safer to try points at least one pixel into the element from the
  # edges, hence the `+1`.
  {left, top, bottom, height} = elementRect
  return tryPoint(
    elementData, elementRect,
    left, +1, Math.round(top + height / 2), 0, tryRight
  )

# Tries a point `(x + dx, y + dy)`. Returns `(x, y)` (and the frame offset) if
# the element passes the tests. Otherwise it tries to the right of whatever is
# at `(x, y)`, `tryRight` times . If nothing succeeds, `false` is returned. `dx`
# and `dy` are used to offset the wanted point `(x, y)` while trying.
tryPoint = (elementData, elementRect, x, dx, y, dy, tryRight = 0) ->
  {window, viewport, parents, element} = elementData
  elementAtPoint = window.document.elementFromPoint(x + dx, y + dy)
  offset = {left: 0, top: 0}
  found = false
  firstLevel = true

  # Ensure that `element`, or a child of `element` (anything inside an `<a>` is
  # clickable too), really is present at (x,y). Note that this is not 100%
  # bullet proof: Combinations of CSS can cause this check to fail, even though
  # `element` isn’t covered. We don’t try to temporarily reset such CSS because
  # of performance. (See further down for the special value `-1` of `tryRight`.)
  if contains(element, elementAtPoint) or tryRight == -1
    found = true
    # If we’re currently in a frame, there might be something on top of the
    # frame that covers `element`. Therefore we ensure that the frame really is
    # present at the point for each parent in `parents`.
    currentWindow = window
    for parent in parents by -1
      # If leaving the devtools container take the devtools zoom into account.
      if utils.isDevtoolsWindow(currentWindow)
        docShell = currentWindow
          .getInterface(Ci.nsIWebNavigation)
          .QueryInterface(Ci.nsIDocShell)
        if docShell
          devtoolsZoom = docShell.contentViewer.fullZoom
          offset.left *= devtoolsZoom
          offset.top  *= devtoolsZoom
          x  *= devtoolsZoom
          y  *= devtoolsZoom
          dx *= devtoolsZoom
          dy *= devtoolsZoom

      offset.left += parent.offset.left
      offset.top  += parent.offset.top
      elementAtPoint = parent.window.document.elementFromPoint(
        offset.left + x + dx, offset.top + y + dy
      )
      firstLevel = false
      unless contains(currentWindow.frameElement, elementAtPoint)
        found = false
        break
      currentWindow = parent.window

  return {x, y, offset} if found

  return false if elementAtPoint == null or tryRight <= 0
  rect = elementAtPoint.getBoundingClientRect()

  # `.getBoundingClientRect()` does not include pseudo-elements that are
  # absolutely positioned so that they go outside of the element (which is
  # common for `/###\`-looking tabs), but calling `.elementAtPoint()` on the
  # pseudo-element _does_ return the element. This means that the covering
  # element’s _rect_ won’t cover the element we’re looking for. If so, it’s
  # better to try again, forcing the element to be considered located at this
  # point. That’s what `-1` for the `tryRight` argument means. This is also used
  # in the 'complementary' pass, to include elements considered covered in
  # earlier passes (which might have been false positives).
  if firstLevel and rect.right <= x + offset.left
    return tryPoint(elementData, elementRect, x, dx, y, dy, -1)

  # If `elementAtPoint` is a parent to `element`, it most likely means that
  # `element` is hidden some way. It can also mean that a pseudo-element of
  # `elementAtPoint` covers `element` partly. Therefore, try once at the most
  # likely point: The center of the part of the rect to the right of `x`.
  if elementRect.right > x and contains(elementAtPoint, element)
    return tryPoint(
      elementData, elementRect,
      (x + elementRect.right) / 2, 0, y, 0, 0
    )

  newX = rect.right - offset.left + 1
  return false if newX > viewport.right or newX > elementRect.right
  return tryPoint(elementData, elementRect, newX, 0, y, 0, tryRight - 1)

# In XUL documents there are “anonymous” elements. These are never returned by
# `document.elementFromPoint` but their closest non-anonymous parents are.
# The same is true for Web Components (where their hosts are returned), with
# the further caveat that they might be nested.
# Note: getBindingParent() has been removed from fx72.
normalize = (element) ->
  element = e while (e = element.ownerDocument.getBindingParent?(element))?
  element = e while (e = element.containingShadowRoot?.host)? # >=fx72
  element = element.parentNode while element.prefix?
  return element

# Returns whether `element` corresponds to `elementAtPoint`. This is only
# complicated for browser elements in the web page content area.
# `.elementAtPoint()` always returns `<tabbrowser#content>` then. The element
# might be in another tab and thus invisible, but `<tabbrowser#content>` is the
# same and visible in _all_ tabs, so we have to check that the element really
# belongs to the current tab.
contains = (element, elementAtPoint) ->
  return false unless elementAtPoint
  container = normalize(element)
  if elementAtPoint.localName == 'tabbrowser' and elementAtPoint.id == 'content'
    {gBrowser} = element.ownerGlobal.top
    tabpanel = gBrowser.getNotificationBox(gBrowser.selectedBrowser)
    return tabpanel.contains(element)
  else
    # Note that `a.contains(a)` is supposed to be true, but strangely aren’t for
    # `<menulist>`s in the Add-ons Manager, so do a direct comparison as well.
    return container == elementAtPoint or container.contains(elementAtPoint)

module.exports = {
  find
}
