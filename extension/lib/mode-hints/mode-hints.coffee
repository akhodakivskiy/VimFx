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
    { markers, callback } = storage

    switch
      when @commands['exit'].match(keyStr)
        vim.enterMode('normal')
        return true

      when @commands['rotate_markers_forward'].match(keyStr)
        hints.rotateOverlappingMarkers(markers, true)
      when @commands['rotate_markers_backward'].match(keyStr)
        hints.rotateOverlappingMarkers(markers, false)

      when @commands['delete_hint_char'].match(keyStr)
        for marker in markers
          marker.deleteHintChar()

      else
        if keyStr not in utils.getHintChars()
          return true
        for marker in markers
          marker.matchHintChar(keyStr)

          if marker.isMatched()
            dontEnterNormalMode = callback(marker, markers)
            vim.enterMode('normal') unless dontEnterNormalMode
            break

    return true

  commands:
    exit:                    ['<escape>']
    rotate_markers_forward:  ['<space>']
    rotate_markers_backward: ['<s-space>']
    delete_hint_char:        ['<backspace>']
