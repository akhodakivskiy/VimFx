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
      markerElement: { offsetHeight: height, offsetWidth: width }
      elementShape: { nonCoveredPoint: { x: left, y: top, offset, rect } }
    } = this

    # Center the marker vertically on the non-covered point.
    top -= height / 2

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

exports.Marker = Marker
