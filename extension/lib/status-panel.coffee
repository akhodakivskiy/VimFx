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

# This file creates VimFx’s status panel, similar to the “URL popup” shown when
# hovering or focusing links.

utils = require('./utils')

injectStatusPanel = (browser, vimfx) ->
  window = browser.ownerGlobal

  statusPanel = window.document.createElement('statuspanel')
  utils.setAttributes(statusPanel, {
    inactive: 'true'
    layer:    'true'
    mirror:   'true'
  })

  # The current browser can usually be retrieved from `window`. However, this
  # runs too early. Instead a browser known to exist is passed in. (_Which_
  # browser is passed doesn’t matter since only their common container is used.)
  window.gBrowser.getBrowserContainer(browser).appendChild(statusPanel)
  module.onShutdown(-> statusPanel.remove())

  shouldHandleNotification = (vim) ->
    return vimfx.options.notifications_enabled and
           vim.window == window and vim == vimfx.getCurrentVim(window)

  vimfx.on('notification', ({vim, message}) ->
    return unless shouldHandleNotification(vim)
    statusPanel.setAttribute('label', message)
    statusPanel.removeAttribute('inactive')
  )

  vimfx.on('hideNotification', ({vim}) ->
    return unless shouldHandleNotification(vim)
    statusPanel.setAttribute('inactive', 'true')
  )

  statusPanel.style.pointerEvents = 'auto'
  utils.listen(statusPanel, 'click', ->
    vimfx.emit('hideNotification')
  )

module.exports = {
  injectStatusPanel
}
