# This file creates VimFx’s toolbar button.

help = require('./help')
translate = require('./translate')
utils = require('./utils')

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

      helpVisible = help.getHelp(window)

      # If we somehow have gotten stuck with `vim.focusType == 'editable'`,
      # allow the buttton to reset to 'none'. (This also hides the help dialog.)
      vimfx.modes.normal.commands.esc.run({vim})

      if vim.mode == 'normal' and not helpVisible
        help.injectHelp(window, vimfx)
      else
        vim._enterMode('normal')
  })
  module.onShutdown(-> cui.destroyWidget(BUTTON_ID))

  vimfx.on('modeDisplayChange', ({vim}) ->
    {window} = vim
    # When the browser starts, the button might not be available yet.
    return unless button = getButton(window)

    tooltip =
      if vim.mode == 'normal'
        translate('button.tooltip.normal')
      else
        translate(
          'button.tooltip.other_mode',
          translate("mode.#{vim.mode}"),
          translate('mode.normal')
        )
    button.setAttribute('tooltiptext', tooltip)
  )

getButton = (window) -> window.document.getElementById(BUTTON_ID)

module.exports = {
  injectButton
  getButton
}
