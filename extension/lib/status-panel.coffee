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

injectStatusPanel = (browser) ->
  window = browser.ownerGlobal

  statusPanel = window.document.createElement('statuspanel')
  utils.setAttributes(statusPanel, {
    inactive: 'true'
    layer:    'true'
    mirror:   'true'
  })
  statusPanel.style.pointerEvents = 'auto'

  window.gBrowser.getBrowserContainer(browser).appendChild(statusPanel)
  module.onShutdown(-> statusPanel.remove())

  return statusPanel

module.exports = {
  injectStatusPanel
}
