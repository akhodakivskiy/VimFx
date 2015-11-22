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
  constructor: (@window, @MINIMUM_SCROLL) ->
    @elements = new Set()
    @largest  = null

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

  # Elements may overflow when zooming in or out. However, the `.scrollHeight`
  # of the element is not correctly updated when the 'overflow' event occurs,
  # making it possible for unscrollable elements to slip in. This method tells
  # whether the largest element really is scrollable, updating it if needed.
  hasOrUpdateLargestScrollable: ->
    if @largest and @isScrollable(@largest)
      return true
    else
      @reject((element) => not @isScrollable(element))
      return @largest?

module.exports = ScrollableElements
