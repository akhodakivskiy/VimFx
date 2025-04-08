# This file contains an abstraction for keeping track of scrollable elements,
# automatically keeping the largest scrollable element up-to-date. It stops
# tracking elements that are removed from the DOM.

utils = require('./utils')

class ScrollableElements
  constructor: (@window) ->
    @elements = new Set()
    @largest = null

  MIN_SCROLL: 5
  MIN_SCROLLABLE_ELEMENT_AREA: 25

  # Even in quirks mode the 'overflow' event is triggered for `<html>`, _not_
  # `<body>`. This method takes care of returning the appropriate element, so
  # we don’t need to think about it anywhere else.
  quirks: (element) ->
    document = element.ownerDocument
    if element == document.documentElement
      return utils.getRootElement(document)
    else
      return element

  # Note: Don’t use `@quirks` here. That causes a hint marker for `<html>` on
  # quirks mode sites, such as Hackernews.
  has: (element) -> @elements.has(element)

  add: (element) ->
    element = @quirks(element)
    @elements.add(element)
    @largest = element if @isLargest(element)

  delete: (element) =>
    element = @quirks(element)
    @elements.delete(element)
    @updateLargest() if @largest == element

  reject: (fn) ->
    @elements.forEach((element) => @elements.delete(element) if fn(element))
    @updateLargest()

  isScrollable: (element) ->
    return false if Cu.isDeadWrapper(element)
    element = @quirks(element)
    return element.scrollTopMax  >= @MIN_SCROLL or
           element.scrollLeftMax >= @MIN_SCROLL

  addChecked: (element) ->
    return unless computedStyle = @window.getComputedStyle(element)
    unless (computedStyle.getPropertyValue('overflow-y') == 'hidden' and
            computedStyle.getPropertyValue('overflow-x') == 'hidden') or
           # There’s no need to track elements so small that they don’t even fit
           # the scrollbars. For example, Gmail has lots of tiny overflowing
           # iframes. Filter those out.
           utils.area(element) < @MIN_SCROLLABLE_ELEMENT_AREA or
           # On some pages, such as Google Groups, 'overflow' events may occur
           # for elements that aren’t even scrollable.
           not @isScrollable(element)
      @add(element)

      # The following scenario can happen (found on 2ality.com): First, the root
      # element overflows just a pixel. That causes an 'overflow' event, but we
      # don’t store it because the overflow is too small. Then, the overflow
      # grows. That does _not_ cause new 'overflow' events. This way, the root
      # element actually becomes scrollable, but we don’t get to know about it,
      # making the root element impossible to scroll if there are other
      # scrollable elements on the page. Therefore, always re-check the root
      # element when adding new scrollable elements. This could in theory happen
      # to _any_ scrollable element, but the by far most common thing is that
      # the root element is scrollable.
      root = @quirks(@window.document.documentElement)
      unless @quirks(element) == root
        @addChecked(root)

  deleteChecked: (element) ->
    # On some pages, such as Gmail, 'underflow' events may occur for elements
    # that are actually still scrollable! If so, keep the element.
    @delete(element) unless @isScrollable(element)

  # It makes the most sense to consider the uppermost scrollable element the
  # largest. In other words, if a scrollable element contains another scrollable
  # element (or a frame containing one), the parent should be considered largest
  # even if the child has greater area.
  isLargest: (element) ->
    return true  unless @largest
    return true  if utils.containsDeep(element, @largest)
    return false if utils.containsDeep(@largest, element)
    return utils.area(element) > utils.area(@largest)

  updateLargest: ->
    # Reset `@largest` and find a new largest scrollable element (if there are
    # any left).
    @largest = null
    @elements.forEach((element) => @largest = element if @isLargest(element))

  # In theory, this method could return `@largest`. In reality, it is not that
  # simple. Elements may overflow when zooming in or out, but the
  # `.scrollHeight` of the element is not correctly updated when the 'overflow'
  # event occurs, making it possible for unscrollable elements to slip in. So
  # this method has to check whether the largest element really is scrollable,
  # and update it if needed. In the case where there is no largest element
  # (left), it _should_ mean that the page hasn’t got any scrollable elements,
  # and the whole page itself isn’t scrollable. However, we cannot be 100% sure
  # that nothing is scrollable (for example, if VimFx is updated in the middle
  # of a session). So in that case, instead of simply returning `null`, return
  # the entire page (the best bet). Not being able to scroll is very annoying.
  filterSuitableDefault: ->
    if @largest and @isScrollable(@largest)
      return @largest
    else
      @reject((element) => not @isScrollable(element))
      return @largest ? @quirks(@window.document.documentElement)

  getPageScrollPosition: ->
    element = @filterSuitableDefault()
    if element.ownerDocument.documentElement.localName == 'svg'
      return [element.ownerGlobal.scrollX, element.ownerGlobal.scrollY]
    else
      return [element.scrollLeft, element.scrollTop]

module.exports = ScrollableElements
