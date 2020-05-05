# This file provides utility functions for working with the viewport.

utils = require('./utils')

MIN_EDGE_DISTANCE = 4

getPosition = (element) ->
  computedStyle = element.ownerGlobal.getComputedStyle(element)
  return computedStyle?.getPropertyValue('position')

isFixed = (element) -> getPosition(element) == 'fixed'

isFixedOrAbsolute = (element) -> getPosition(element) in ['fixed', 'absolute']

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
  area   = Math.round(width * height)

  return {
    left, right, top, bottom
    height, width, area
  }

getAllRangesInsideViewport = (window, viewport, offset = {left: 0, top: 0}) ->
  selection = window.getSelection()
  {rangeCount} = selection
  ranges = []

  if rangeCount > 0
    {header, headerBottom, footer, footerTop} =
      getFixedHeaderAndFooter(window, viewport)

    # Many sites use `text-indent: -9999px;` or similar to hide text intended
    # for screen readers only. That text can still be selected and found by
    # searching, though. Therefore, we have to allow selection ranges that are
    # within the viewport vertically but not horizontally, even though they
    # actually are outside the viewport. Otherwise you won’t be able to press
    # `n` to get past those elements (instead, `n` would start over from the top
    # of the viewport).
    for index in [0...rangeCount]
      range = selection.getRangeAt(index)
      continue if range.collapsed
      rect = range.getBoundingClientRect()
      if (rect.top >= headerBottom - MIN_EDGE_DISTANCE and
          rect.bottom <= footerTop + MIN_EDGE_DISTANCE) or
         header?.contains(range.commonAncestorContainer) or
         footer?.contains(range.commonAncestorContainer)
        adjustedRect = {
          left: offset.left + rect.left
          top: offset.top + rect.top
          right: offset.left + rect.right
          bottom: offset.top + rect.bottom
          width: rect.width
          height: rect.height
        }
        ranges.push({range, rect: adjustedRect})

  # Note: accessing frameElement fails on oop iframes (fission), so we skip them
  for frame in window.frames when (try frame.frameElement)
    {viewport: frameViewport, offset: frameOffset} =
      getFrameViewport(frame.frameElement, viewport) ? {}
    continue unless frameViewport
    newOffset = {
      left: offset.left + frameOffset.left
      top: offset.top + frameOffset.top
    }
    frameRanges = getAllRangesInsideViewport(frame, frameViewport, newOffset)
    ranges.push(frameRanges...)

  return ranges

getFirstNonWhitespace = (element) ->
  window = element.ownerGlobal
  viewport = getWindowViewport(window)
  result = null
  utils.walkTextNodes(element, (textNode) ->
    return false unless /\S/.test(textNode.data)
    offset = getFirstVisibleNonWhitespaceOffset(textNode, viewport)
    if offset >= 0
      result = [textNode, offset]
      return true
  )
  return result

getFirstVisibleNonWhitespaceOffset = (textNode, viewport) ->
  firstVisibleOffset = getFirstVisibleOffset(textNode, viewport)
  if firstVisibleOffset?
    offset = textNode.data.slice(firstVisibleOffset).search(/\S/)
    return firstVisibleOffset + offset if offset >= 0
  return -1

getFirstVisibleOffset = (textNode, viewport) ->
  {length} = textNode.data
  return null if length == 0
  {headerBottom} = getFixedHeaderAndFooter(textNode.ownerGlobal, viewport)
  [nonMatch, match] = utils.bisect(0, length - 1, (offset) ->
    range = textNode.ownerDocument.createRange()
    # Using a zero-width range sometimes gives a bad rect, so make it span one
    # character instead.
    range.setStart(textNode, offset)
    range.setEnd(textNode, offset + 1)
    rect = range.getBoundingClientRect()
    # Ideally, we should also make sure that the text node is visible
    # horizintally, but there seems to be no performant way of doing so.
    # Luckily, horizontal scrolling is much less common than vertical.
    return rect.top >= headerBottom - MIN_EDGE_DISTANCE
  )
  return match

getFirstVisibleRange = (window, viewport) ->
  ranges = getAllRangesInsideViewport(window, viewport)
  first = null
  for item in ranges
    if not first or item.rect.top < first.rect.top
      first = item
  return if first then first.range else null

getFirstVisibleText = (window, viewport) ->
  for element in window.document.getElementsByTagName('*')
    rect = element.getBoundingClientRect()
    continue unless isInsideViewport(rect, viewport)

    if element.contentWindow and
       not utils.checkElementOrAncestor(element, isFixed)
      {viewport: frameViewport} = getFrameViewport(element, viewport) ? {}
      continue unless frameViewport
      result = getFirstVisibleText(element.contentWindow, frameViewport)
      return result if result
      continue

    nonEmptyTextNodes =
      Array.prototype.filter.call(element.childNodes, utils.isNonEmptyTextNode)
    continue if nonEmptyTextNodes.length == 0

    continue if utils.checkElementOrAncestor(element, isFixed)

    for textNode in nonEmptyTextNodes
      offset = getFirstVisibleNonWhitespaceOffset(textNode, viewport)
      return [textNode, offset] if offset >= 0

  return null

# Adapted from Firefox’s source code for `<space>` scrolling (which is where the
# arbitrary constants below come from).
#
# coffeelint: disable=max_line_length
# <https://hg.mozilla.org/mozilla-central/file/4d75bd6fd234/layout/generic/nsGfxScrollFrame.cpp#l3829>
# coffeelint: enable=max_line_length
getFixedHeaderAndFooter = (window) ->
  viewport = getWindowViewport(window)
  header = null
  headerBottom = viewport.top
  footer = null
  footerTop = viewport.bottom
  maxHeight = viewport.height / 3
  minWidth = Math.min(viewport.width / 2, 800)

  # Restricting the candidates for headers and footers to the most likely set of
  # elements results in a noticeable performance boost.
  candidates = window.document.querySelectorAll(
    'div, ul, nav, header, footer, section'
  )

  for candidate in candidates
    rect = candidate.getBoundingClientRect()
    continue unless rect.height <= maxHeight and rect.width >= minWidth
    # Checking for `position: fixed;` or `position: absolute;` is the absolutely
    # most expensive operation, so that is done last.
    switch
      when rect.top <= headerBottom and rect.bottom > headerBottom and
           isFixedOrAbsolute(candidate)
        header = candidate
        headerBottom = rect.bottom
      when rect.bottom >= footerTop and rect.top < footerTop and
           isFixedOrAbsolute(candidate)
        footer = candidate
        footerTop = rect.top

  return {header, headerBottom, footer, footerTop}

getFrameViewport = (frame, parentViewport) ->
  rect = frame.getBoundingClientRect()
  return null unless isInsideViewport(rect, parentViewport)

  # `.getComputedStyle()` may return `null` if the computed style isn’t availble
  # yet. If so, consider the element not visible.
  return null unless computedStyle = frame.ownerGlobal.getComputedStyle(frame)
  offset = {
    left: rect.left +
      parseFloat(computedStyle.getPropertyValue('border-left-width')) +
      parseFloat(computedStyle.getPropertyValue('padding-left'))
    top: rect.top +
      parseFloat(computedStyle.getPropertyValue('border-top-width')) +
      parseFloat(computedStyle.getPropertyValue('padding-top'))
    right: rect.right -
      parseFloat(computedStyle.getPropertyValue('border-right-width')) -
      parseFloat(computedStyle.getPropertyValue('padding-right'))
    bottom: rect.bottom -
      parseFloat(computedStyle.getPropertyValue('border-bottom-width')) -
      parseFloat(computedStyle.getPropertyValue('padding-bottom'))
  }

  # Calculate the visible part of the frame, according to the parent.
  viewport = getWindowViewport(frame.contentWindow)
  left = viewport.left + Math.max(parentViewport.left - offset.left, 0)
  top  = viewport.top  + Math.max(parentViewport.top  - offset.top,  0)
  right  = viewport.right  + Math.min(parentViewport.right  - offset.right,  0)
  bottom = viewport.bottom + Math.min(parentViewport.bottom - offset.bottom, 0)

  return {
    viewport: {
      left, top, right, bottom
      width: right - left
      height: bottom - top
    }
    offset
  }

# Returns the minimum of `element.clientHeight` and the height of the viewport,
# taking fixed headers and footers into account.
getViewportCappedClientHeight = (element) ->
  window = element.ownerGlobal
  viewport = getWindowViewport(window)
  {headerBottom, footerTop} = getFixedHeaderAndFooter(window)
  return Math.min(element.clientHeight, footerTop - headerBottom)

getWindowViewport = (window) ->
  {
    clientWidth, clientHeight # Viewport size excluding scrollbars, usually.
    scrollWidth, scrollHeight
  } = utils.getRootElement(window.document)
  {innerWidth, innerHeight} = window # Viewport size including scrollbars.
  # When there are no scrollbars `clientWidth` and `clientHeight` might be too
  # small. Then we use `innerWidth` and `innerHeight` instead.
  width  = if scrollWidth  > innerWidth  then clientWidth  else innerWidth
  height = if scrollHeight > innerHeight then clientHeight else innerHeight
  return {
    left: 0
    top: 0
    right: width
    bottom: height
    width
    height
  }

isInsideViewport = (rect, viewport) ->
  return \
    rect.left   <= viewport.right  - MIN_EDGE_DISTANCE and
    rect.top    <= viewport.bottom - MIN_EDGE_DISTANCE and
    rect.right  >= viewport.left   + MIN_EDGE_DISTANCE and
    rect.bottom >= viewport.top    + MIN_EDGE_DISTANCE

windowScrollProperties = {
  clientHeight: 'innerHeight'
  scrollTopMax: 'scrollMaxY'
  scrollLeftMax: 'scrollMaxX'
}

scroll = (
  element, {method, type, directions, amounts, properties, adjustment, smooth}
) ->
  if element.ownerDocument.documentElement.localName == 'svg'
    element = element.ownerGlobal
    properties = properties?.map(
      (property) -> windowScrollProperties[property] ? property
    )

  options = {
    behavior: if smooth then 'smooth' else 'instant'
  }

  for direction, index in directions
    amount = amounts[index]
    options[direction] = -Math.sign(amount) * adjustment + switch type
      when 'lines'
        amount
      when 'pages'
        amount *
          if properties[index] == 'clientHeight'
            getViewportCappedClientHeight(element)
          else
            element[properties[index]]
      when 'other'
        Math.min(amount, element[properties[index]])

  element[method](options)

module.exports = {
  MIN_EDGE_DISTANCE
  adjustRectToViewport
  getAllRangesInsideViewport
  getFirstNonWhitespace
  getFirstVisibleNonWhitespaceOffset
  getFirstVisibleOffset
  getFirstVisibleRange
  getFirstVisibleText
  getFixedHeaderAndFooter
  getFrameViewport
  getViewportCappedClientHeight
  getWindowViewport
  isInsideViewport
  scroll
}
