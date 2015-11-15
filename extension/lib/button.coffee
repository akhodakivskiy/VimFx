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

# This file creates VimFx’s toolbar button.

help      = require('./help')
translate = require('./l10n')
utils     = require('./utils')

cui = Cu.import('resource:///modules/CustomizableUI.jsm', {}).CustomizableUI

BUTTON_ID = 'VimFxButton'

injectButton = (vimfx) ->
  cui.createWidget({
    id: BUTTON_ID
    defaultArea: cui.AREA_NAVBAR
    label: 'VimFx'
    tooltiptext: translate('button.tooltip.normal')
    onCommand: (event) ->
      button = event.originalTarget
      window = button.ownerGlobal
      return unless vim = vimfx.getCurrentVim(window)

      if vim.mode == 'normal'
        help.injectHelp(window, vimfx)
      else
        vim.enterMode('normal')
  })
  module.onShutdown(cui.destroyWidget.bind(cui, BUTTON_ID))

  vimfx.on('modeDisplayChange', (vim) ->
    {window} = vim
    # When the browser starts, the button might not be available yet.
    return unless button = getButton(window)

    tooltip =
      if vim.mode == 'normal'
        translate('button.tooltip.normal')
      else
        translate('button.tooltip.other_mode',
                  translate("mode.#{vim.mode}"), translate('mode.normal'))
    button.setAttribute('tooltiptext', tooltip)
  )

getButton = (window) -> window.document.getElementById(BUTTON_ID)

module.exports = {
  injectButton
  getButton
}
