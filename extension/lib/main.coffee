###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
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

{ loadCss }             = require('./utils')
{ addEventListeners
, vimBucket }           = require('./events')
{ setButtonInstallPosition
, addToolbarButton }    = require('./button')
options                 = require('./options')
{ watchWindows }        = require('./window-utils')
test                    = try require('../test/index')

module.exports = (data, reason) ->
  test?()

  if reason == ADDON_INSTALL
    # Position the toolbar button right before the default Bookmarks button.
    # If Bookmarks button is hidden the VimFx button will be appended to the
    # toolbar.
    setButtonInstallPosition('nav-bar', 'bookmarks-menu-button-container')

  loadCss('style')

  options.observe()

  watchWindows(addEventListeners, 'navigator:browser')
  watchWindows(addToolbarButton.bind(undefined, vimBucket), 'navigator:browser')
