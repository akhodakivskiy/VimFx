###
# Copyright Anton Khodakivskiy 2013, 2014.
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

utils = require('../utils')
hints = require('./hints')

{ isEscCommandKey } = require('../commands')

exports.mode_hints =
  onEnter: (vim, storage, callback) ->
    markers = hints.injectHints(vim.window)
    if markers?.length > 0
      storage.markers  = markers
      storage.callback = callback
    else
      vim.enterMode('normal')

  onLeave: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.callback = undefined

  onInput: (vim, storage, keyStr, event) ->
    if isEscCommandKey(keyStr)
      vim.enterMode('normal')
      return true

    { markers, callback } = storage

    switch keyStr
      when '<space>'
        hints.rotateOverlappingMarkers(markers, true)
      when '<s-space>'
        hints.rotateOverlappingMarkers(markers, false)

      when '<backspace>'
        for marker in markers
          marker.deleteHintChar()

      else
        if keyStr not in utils.getHintChars()
          return true
        for marker in markers
          marker.matchHintChar(keyStr)

          if marker.isMatched()
            marker.reward() # Add element features to the bloom filter.
            dontEnterNormalMode = callback(marker, markers)
            vim.enterMode('normal') unless dontEnterNormalMode
            break

    return true
