###
# Copyright Simon Lydell 2015.
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

# This file contains an abstraction for keeping track of scrollable elements,
# automatically keeping the largest scrollable element up-to-date. It stops
# tracking elements that are removed from the DOM.

utils = require('./utils')

class ScrollableElements
  constructor: (@window) ->
    @elements = new Set()
    @largest  = null

  MINIMUM_SCROLL: 5
  MINIMUM_SCROLLABLE_ELEMENT_AREA: 25

  # In quirks mode (when the page lacks a doctype), such as on Hackernews,
  # `<body>` is considered the root element rather than `<html>`. The 'overflow'
  # event is triggered for `<html>` though (_not_ `<body>`!). This method takes
  # care of returning the appropriate element, so we don’t need to think about
  # it anywhere else.
  quirks: (element) ->
    document = element.ownerDocument
    if element == document.documentElement and
       document.compatMode == 'BackCompat' and document.body?
      return document.body
    else
      return element

  has: (element) -> @elements.has(@quirks(element))

  add: (element) ->
    element = @quirks(element)
    @elements.add(element)
    utils.onRemoved(@window, element, @delete.bind(this, element))
    @largest = element if @isLargest(element)

  delete: (element) =>
    element = @quirks(element)
    @elements.delete(element)
    @updateLargest() if @largest == element

  reject: (fn) ->
    @elements.forEach((element) => @elements.delete(element) if fn(element))
    @updateLargest()

  isScrollable: (element) ->
    element = @quirks(element)
    return element.scrollTopMax  >= @MINIMUM_SCROLL or
           element.scrollLeftMax >= @MINIMUM_SCROLL

  addChecked: (element) ->
    return unless computedStyle = @window.getComputedStyle(element)
    unless (computedStyle.getPropertyValue('overflow-y') == 'hidden' and
            computedStyle.getPropertyValue('overflow-x') == 'hidden') or
           # There’s no need to track elements so small that they don’t even fit
           # the scrollbars. For example, Gmail has lots of tiny overflowing
           # iframes. Filter those out.
           utils.area(element) < @MINIMUM_SCROLLABLE_ELEMENT_AREA or
           # On some pages, such as Google Groups, 'overflow' events may occur
           # for elements that aren’t even scrollable.
           not @isScrollable(element)
      @add(element)

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

module.exports = ScrollableElements
