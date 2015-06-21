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

createAPI             = require('./api')
button                = require('./button')
defaults              = require('./defaults')
{ addEventListeners } = require('./events')
modes                 = require('./modes')
options               = require('./options')
parsePref             = require('./parse-prefs')
prefs                 = require('./prefs')
utils                 = require('./utils')
VimFx                 = require('./vimfx')
{ watchWindows }      = require('./window-utils')
test                  = try require('../test/index')

{ utils: Cu } = Components

Cu.import('resource://gre/modules/AddonManager.jsm')

module.exports = (data, reason) ->
  parsedOptions = {}
  for pref of defaults.all_options
    parsedOptions[pref] = parsePref(pref)
  vimfx = new VimFx(modes, parsedOptions)
  vimfx.id      = data.id
  vimfx.version = data.version
  AddonManager.getAddonByID(vimfx.id, (info) -> vimfx.info = info)

  # Setup the public API. The URL is encoded (which means that there will be
  # only ASCII characters) so that the pref can be read using a simple
  # `Services.prefs.getCharPref()` (which only supports ASCII characters).
  api_url = encodeURI("#{ data.resourceURI.spec }lib/public.js")
  { setAPI } = Cu.import(api_url, {})
  setAPI(createAPI(vimfx))
  module.onShutdown(-> Cu.unload(api_url))
  prefs.set('api_url', api_url)

  test?(vimfx)

  utils.loadCss('style')

  options.observe(vimfx)

  prefs.observe('', (pref) ->
    if pref.startsWith('mode.') or pref.startsWith('custom.')
      vimfx.createKeyTrees()
    else if pref of defaults.all_options
      vimfx.options[pref] = parsePref(pref)
  )

  watchWindows(button.injectButton.bind(null, vimfx), 'navigator:browser')
  watchWindows(addEventListeners.bind(null, vimfx), 'navigator:browser')
