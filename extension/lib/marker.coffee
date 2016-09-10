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
    @weight = @wrapper.combinedArea
    @width = 0
    @height = 0
    @hint = ''
    @originalHint = null
    @text = @wrapper.text?.toLowerCase() ? ''
    @visible = true
    @zoom = 1
    @viewport = null
    @position = null
    @originalPosition = null
    @dx = 0
    @dy = 0

  reset: ->
    @setHint(@originalHint)
    @show()
    @refreshPosition()

  show: -> @setVisibility(true)
  hide: -> @setVisibility(false)

  setVisibility: (@visible) ->
    @markerElement.classList.toggle('marker--hidden', not @visible)

  # To be called when the marker has been both assigned a hint and inserted
  # into the DOM, and thus gotten a width and height.
  setPosition: (@viewport, @zoom) ->
    {
      textOffset
      width: elementWidth
      nonCoveredPoint: {x: left, y: top, offset}
    } = @elementShape

    rect = @markerElement.getBoundingClientRect()

    @width  = rect.width  / @zoom
    @height = rect.height / @zoom

    # Center the marker vertically on the non-covered point.
    top -= Math.ceil(@height / 2)

    if textOffset?
      # Move the marker just to the left of the text of its element.
      left -= Math.max(0, @width - textOffset)
    else
      # Otherwise make sure that it doesn’t flow outside the right side of its
      # element. This is to avoid the following situation (where `+` is a small
      # button, `Link text` is a (larger) link and `DAG` and `E` are the hints
      # placed on top of them.) This makes it clearer which hint does what.
      # Example site: Hackernews.
      #
      #     z-layer   before       after
      #     bottom    +Link text     +Link text
      #     middle    DAG          DAG
      #     top       E              E
      left -= Math.max(0, @width - elementWidth)

    # Make the position relative to the top frame.
    left += offset.left
    top  += offset.top

    @originalPosition = {left, top}
    @moveTo(left + @dx, top + @dy)

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

  updatePosition: (@dx, @dy) ->
    @moveTo(@originalPosition.left + @dx, @originalPosition.top + @dy)

  refreshPosition: ->
    @setPosition(@viewport, @zoom)

  setHint: (@hint) ->
    @originalHint ?= @hint
    @markerElement.textContent = ''
    fragment = @document.createDocumentFragment()
    utils.createBox(@document, 'marker-char', fragment, char) for char in @hint
    @markerElement.appendChild(fragment)

  matchHint: (hint) ->
    return @hint.startsWith(hint)

  matchText: (strings) ->
    return strings.every((string) => @text.includes(string))

  markMatchedPart: (hint) ->
    matchEnd = if @matchHint(hint) then hint.length else 0
    for child, index in @markerElement.children
      child.classList.toggle('marker-char--matched', index < matchEnd)
    return

  markMatched: (matched) ->
    @markerElement.classList.toggle('marker--matched', matched)

  markHighlighted: (highlighted) ->
    @markerElement.classList.toggle('marker--highlighted', highlighted)

module.exports = Marker
