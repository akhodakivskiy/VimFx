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

# This file pulls in all the different parts of VimFx, initializes them, and
# stiches them together.

createAPI      = require('./api')
button         = require('./button')
defaults       = require('./defaults')
UIEventManager = require('./events')
messageManager = require('./message-manager')
modes          = require('./modes')
options        = require('./options')
parsePref      = require('./parse-prefs')
prefs          = require('./prefs')
utils          = require('./utils')
VimFx          = require('./vimfx')
test           = try require('../test/index')

Cu.import('resource://gre/modules/AddonManager.jsm')

module.exports = (data, reason) ->
  parsedOptions = {}
  for pref of defaults.all_options
    parsedOptions[pref] = parsePref(pref)
  vimfx = new VimFx(modes, parsedOptions)
  vimfx.id      = data.id
  vimfx.version = data.version
  AddonManager.getAddonByID(vimfx.id, (info) -> vimfx.info = info)

  # Setup the public API.
  apiUrl = "#{ data.resourceURI.spec }lib/public.js"
  { setAPI } = Cu.import(apiUrl, {})
  setAPI(createAPI(vimfx))
  module.onShutdown(-> Cu.unload(apiUrl))
  prefs.set('apiUrl', apiUrl)

  utils.loadCss('style')

  options.observe(vimfx)

  prefs.observe('', (pref) ->
    if pref.startsWith('mode.') or pref.startsWith('custom.')
      vimfx.createKeyTrees()
    else if pref of defaults.all_options
      value = parsePref(pref)
      vimfx.options[pref] = value
  )

  button.injectButton(vimfx)

  test?(vimfx)

  windows = new WeakSet()
  messageManager.listen('tabCreated', (data, { target }) ->
    return false unless target.getAttribute('messagemanagergroup') == 'browsers'

    window = target.ownerGlobal
    vimfx.addVim(target)

    unless windows.has(window)
      windows.add(window)
      eventManager = new UIEventManager(vimfx, window)
      eventManager.addListeners(vimfx, window)

    return __SCRIPT_URI_SPEC__
  )

  messageManager.load('bootstrap')
