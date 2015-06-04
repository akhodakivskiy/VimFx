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

help      = require('./help')
translate = require('./l10n')

BUTTON_ID = 'VimFxButton'

injectButton = (vimfx, window) ->
  cui = window.CustomizableUI
  button = null
  cui.createWidget({
    id: BUTTON_ID
    defaultArea: cui.AREA_NAVBAR
    label: 'VimFx'
    tooltiptext: translate('button.tooltip.normal')
    onCommand: ->
      mode = button.getAttribute('vimfx-mode')
      if mode == 'normal'
        help.injectHelp(window, vimfx)
      else
        vimfx.currentVim.enterMode('normal')
    onCreated: (node) ->
      button = node
      button.setAttribute('vimfx-mode', 'normal')
      vimfx.on('modeChange',       updateButton.bind(null, button))
      vimfx.on('currentVimChange', updateButton.bind(null, button))
  })
  module.onShutdown(cui.destroyWidget.bind(cui, BUTTON_ID))

updateButton = (button, { mode }) ->
  button.setAttribute('vimfx-mode', mode)
  tooltip =
    if mode == 'normal'
      translate('button.tooltip.normal')
    else
      translate('button.tooltip.other_mode', translate("mode.#{ mode }"),
                translate('mode.normal'))
  button.setAttribute('tooltiptext', tooltip)

module.exports = {
  injectButton
  BUTTON_ID
}
