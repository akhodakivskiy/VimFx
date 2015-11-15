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
# tracking elements that are removed from the DOM, or whose containg frame is
# removed.

utils = require('./utils')

class ScrollableElements
  constructor: (@window) ->
    @elements = new Set()
    @frames   = new WeakSet()
    @largest  = null

  has: (element) -> @elements.has(element)

  add: (element) ->
    @elements.add(element)
    utils.onRemoved(@window, element, @delete.bind(this, element))
    @addFrame(element)

    if not @largest or utils.area(element) > utils.area(@largest)
      @largest = element

  addFrame: (element) ->
    window = element.ownerDocument.defaultView
    frame  = window.frameElement
    return if not frame or @frames.has(frame)

    utils.onRemoved(@window, frame, =>
      @frames.delete(frame)
      @reject(utils.windowContainsDeep.bind(null, window))
    )

  delete: (element) =>
    @elements.delete(element)
    @updateLargest() if @largest == element

  reject: (fn) ->
    @elements.forEach((element) => @elements.delete(element) if fn(element))
    @updateLargest()

  updateLargest: ->
    @largest = null

    # Find a new largest scrollable element (if there are any left).
    largestArea = -1
    @elements.forEach((element) =>
      area = utils.area(element)
      if area > largestArea
        @largest = element
        largestArea = area
    )

module.exports = ScrollableElements
