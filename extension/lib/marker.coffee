###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
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

# This file contains an abstraction for hint markers. It creates the UI for a
# marker and provides methods to manipulate the markers.

utils = require('./utils')

class Marker
  # `@wrapper` is a stand-in for the element that the marker represents. See
  # `MarkerContainer::injectHints` for more information.
  constructor: (@wrapper, @document, {@isComplementary}) ->
    @elementShape  = @wrapper.shape
    @markerElement = utils.createBox(@document, 'marker')
    @markerElement.setAttribute('data-type', @wrapper.type)
    @weight = @elementShape.area
    @width = 0
    @height = 0
    @hint = ''
    @hintIndex = 0
    @visible = true
    @zoom = 1
    @viewport = null
    @position = null
    @originalPosition = null

  reset: ->
    @setHint(@hint)
    @show()

  show: -> @setVisibility(true)
  hide: -> @setVisibility(false)

  setVisibility: (@visible) ->
    @markerElement.classList.toggle('marker--hidden', not @visible)

  # To be called when the marker has been both assigned a hint and inserted
  # into the DOM, and thus gotten a width and height.
  setPosition: (@viewport, @zoom) ->
    {
      markerElement: {clientWidth, clientHeight}
      elementShape: {nonCoveredPoint: {x: left, y: top, offset}}
    } = this

    @width  = clientWidth  / @zoom
    @height = clientHeight / @zoom

    # Center the marker vertically on the non-covered point.
    top -= Math.ceil(@height / 2)

    # Make the position relative to the top frame.
    left += offset.left
    top  += offset.top

    @originalPosition = {left, top}
    @moveTo(left, top)

  moveTo: (left, top) ->
    # Make sure that the marker stays within the viewport.
    left = Math.min(left, @viewport.right  - @width)
    top  = Math.min(top,  @viewport.bottom - @height)
    left = Math.max(left, @viewport.left)
    top  = Math.max(top,  @viewport.top)

    # Take the current zoom into account.
    left = Math.round(left * @zoom)
    top  = Math.round(top  * @zoom)

    # The positioning is absolute.
    @markerElement.style.left = "#{left}px"
    @markerElement.style.top  = "#{top}px"

    # For quick access.
    @position = {
      left, right: left + @width,
      top, bottom: top + @height,
    }

  updatePosition: (dx, dy) ->
    @moveTo(@originalPosition.left + dx, @originalPosition.top + dy)

  setHint: (@hint) ->
    @hintIndex = 0
    @markerElement.textContent = ''
    fragment = @document.createDocumentFragment()
    utils.createBox(@document, 'marker-char', fragment, char) for char in @hint
    @markerElement.appendChild(fragment)

  matchHintChar: (char) ->
    if char == @hint[@hintIndex]
      @toggleLastHintChar(true)
      @hintIndex += 1
      return true
    return false

  deleteHintChar: ->
    if @hintIndex > 0
      @hintIndex -= 1
      @toggleLastHintChar(false)

  toggleLastHintChar: (visible) ->
    @markerElement.children[@hintIndex]
      .classList.toggle('marker-char--matched', visible)

  isMatched: -> (@hintIndex == @hint.length)

  markMatched: (matched) ->
    @markerElement.classList.toggle('marker--matched', matched)

module.exports = Marker
