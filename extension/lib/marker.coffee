###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014.
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

# Wraps the markable element and provides methods to manipulate the markers.
class Marker
  # Creates the marker DOM node.
  constructor: (@element, @elementShape, { @semantic, @type }) ->
    document = @element.ownerDocument
    @markerElement = document.createElement('div')
    @markerElement.classList.add('VimFxHintMarker')
    @weight = @elementShape.area
    @numChildren = 0

  reset: ->
    @setHint(@hint)
    @show()

  show: -> @setVisibility(true)
  hide: -> @setVisibility(false)
  setVisibility: (visible) ->
    @markerElement.classList.toggle('VimFxHiddenHintMarker', not visible)

  # To be called when the marker has been both assigned a hint and inserted
  # into the DOM, and thus gotten a height and width.
  setPosition: (viewport) ->
    {
      markerElement: { clientHeight: height, clientWidth: width }
      elementShape: { nonCoveredPoint: { x: left, y: top, offset, rect } }
    } = this

    # Center the marker vertically on the non-covered point.
    top -= Math.ceil(height / 2)

    # Make sure that the marker stays within its element (vertically).
    top = Math.min(top, rect.bottom - height)
    top = Math.max(top, rect.top)

    # Make the position relative to the top frame.
    left += offset.left
    top  += offset.top

    # Make sure that the marker stays within the viewport.
    left = Math.min(left, viewport.right  - width)
    top  = Math.min(top,  viewport.bottom - height)
    left = Math.max(left, viewport.left)
    top  = Math.max(top,  viewport.top)

    # The positioning is absolute.
    @markerElement.style.left = "#{ left }px"
    @markerElement.style.top  = "#{ top }px"

    # For quick access.
    @position = {
      left, right: left + width,
      top, bottom: top + height,
      height, width
    }

  setHint: (@hint) ->
    @hintIndex = 0

    document = @element.ownerDocument

    while @markerElement.hasChildNodes()
      @markerElement.firstChild.remove()

    fragment = document.createDocumentFragment()
    for char in @hint
      charContainer = document.createElement('span')
      charContainer.textContent = char
      fragment.appendChild(charContainer)

    @markerElement.appendChild(fragment)

  matchHintChar: (char) ->
    if char == @hint[@hintIndex]
      @toggleLastHintChar(true)
      @hintIndex++
      return true
    return false

  deleteHintChar: ->
    if @hintIndex > 0
      @hintIndex--
      @toggleLastHintChar(false)

  toggleLastHintChar: (visible) ->
    @markerElement.children[@hintIndex]
      .classList.toggle('VimFxCharMatch', visible)

  isMatched: -> (@hintIndex == @hint.length)

  markMatched: (matched) ->
    @markerElement.classList.toggle('VimFxMatchedHintMarker', matched)

# Finds all stacks of markers that overlap each other (by using `getStackFor`)
# (#1), and rotates their `z-index`:es (#2), thus alternating which markers are
# visible.
rotateOverlappingMarkers = (originalMarkers, forward) ->
  # Shallow working copy. This is necessary since `markers` will be mutated and
  # eventually empty.
  markers = originalMarkers[..]

  # (#1)
  stacks = (getStackFor(markers.pop(), markers) while markers.length > 0)

  # (#2)
  # Stacks of length 1 don't participate in any overlapping, and can therefore
  # be skipped.
  for stack in stacks when stack.length > 1
    # This sort is not required, but makes the rotation more predictable.
    stack.sort((a, b) -> a.markerElement.style.zIndex -
                         b.markerElement.style.zIndex)

    # Array of z-indices.
    indexStack = (marker.markerElement.style.zIndex for marker in stack)
    # Shift the array of indices one item forward or back.
    if forward
      indexStack.unshift(indexStack.pop())
    else
      indexStack.push(indexStack.shift())

    for marker, index in stack
      marker.markerElement.style.zIndex = indexStack[index]

  return

# Get an array containing `marker` and all markers that overlap `marker`, if
# any, which is called a "stack". All markers in the returned stack are spliced
# out from `markers`, thus mutating it.
getStackFor = (marker, markers) ->
  stack = [marker]

  { top, bottom, left, right } = marker.position

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
      index++

  return stack

exports.Marker                   = Marker
exports.rotateOverlappingMarkers = rotateOverlappingMarkers
