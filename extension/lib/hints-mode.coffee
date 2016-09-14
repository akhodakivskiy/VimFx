###
# Copyright Simon Lydell 2016.
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

# This file contains a few helper functions for Hints mode, that didn’t really
# fit in modes.coffee.

activateMatch = (vim, storage, match, matchedMarkers, callback) ->
  {markerContainer} = storage

  marker.markMatched(true) for marker in matchedMarkers

  # Prevent `onLeave` cleanup if the callback enters another mode.
  storage.skipOnLeaveCleanup = true
  again = callback(matchedMarkers[0], storage.count, match.keyStr)
  storage.skipOnLeaveCleanup = false

  switchedMode = (vim.mode != 'hints')

  if again and not switchedMode
    storage.count -= 1
    vim.window.setTimeout((->
      marker.markMatched(false) for marker in matchedMarkers
      updateVisualFeedback(vim, markerContainer, [])
      return
    ), vim.options['hints.matched_timeout'])
    markerContainer.reset()

  else
    vim.window.setTimeout((->
      # Don’t clean up if Hints mode has been re-entered before the
      # timeout has passed.
      cleanup(vim, storage) unless vim.mode == 'hints'
    ), vim.options['hints.matched_timeout'])

    unless switchedMode
      storage.skipOnLeaveCleanup = true
      vim._enterMode('normal')
      storage.skipOnLeaveCleanup = false

cleanup = (vim, storage) ->
  {markerContainer, matchText} = storage
  markerContainer?.remove()
  vim._run('clear_selection') if matchText and vim.mode != 'caret'
  if vim.options.notify_entered_keys and
     markerContainer.enteredText == vim._state.lastNotification
    vim.hideNotification()
  storage.clearInterval?()
  for key of storage
    storage[key] = null
  return

getChar = (match, {markerContainer, matchText}) ->
  {unmodifiedKey} = match
  unmodifiedKey = unmodifiedKey.toLowerCase() unless matchText

  isHintChar = switch
    when not matchText
      true
    when unmodifiedKey.length == 1
      markerContainer.isHintChar(unmodifiedKey)
    else
      false

  char = if isHintChar then unmodifiedKey else match.rawKey
  if char.length == 1
    return {char, isHintChar}
  else
    return {char: null, isHintChar: false}

updateVisualFeedback = (vim, markerContainer, visibleMarkers) ->
  hasEnteredText = (markerContainer.enteredText != '')

  if vim.options.notify_entered_keys
    if hasEnteredText
      vim._notifyPersistent(markerContainer.enteredText)
    else
      vim.hideNotification()

  elements = visibleMarkers.map((marker) ->
    return {
      elementIndex: marker.wrapper.elementIndex
      selectAll: marker.highlighted and hasEnteredText
    }
  )
  strings = markerContainer.splitEnteredText()
  vim._send('highlightMarkableElements', {elements, strings})

isMatched = (visibleMarkers, {enteredHint}) ->
  isUnique = (new Set(visibleMarkers.map((marker) -> marker.hint)).size == 1)
  if isUnique
    return {byText: true, byHint: (enteredHint == visibleMarkers[0].hint)}
  else
    return {byText: false, byHint: false}

module.exports = {
  activateMatch
  cleanup
  getChar
  updateVisualFeedback
  isMatched
}
