###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015.
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

  utils.loadCss('style')

  options.observe(vimfx)

  skipCreateKeyTrees = false
  prefs.observe('', (pref) ->
    if pref.startsWith('mode.') or pref.startsWith('custom.')
      vimfx.createKeyTrees() unless skipCreateKeyTrees
    else if pref of defaults.all_options
      value = parsePref(pref)
      vimfx.options[pref] = value
  )

  button.injectButton(vimfx)

  setWindowAttribute = (window, name, value = 'none') ->
    window.document.documentElement.setAttribute("vimfx-#{name}", value)

  onModeDisplayChange = (vimOrEvent) ->
    window = vimOrEvent.window ? vimOrEvent.originalTarget.ownerGlobal

    # The 'modeChange' event provides the `vim` object that changed mode, but it
    # might not be the current `vim` anymore, so always get the current one.
    return unless vim = vimfx.getCurrentVim(window)

    setWindowAttribute(window, 'mode', vim.mode)
    vimfx.emit('modeDisplayChange', vim)

  vimfx.on('modeChange', onModeDisplayChange)
  vimfx.on('TabSelect',  onModeDisplayChange)

  vimfx.on('focusTypeChange', ({vim, focusType}) ->
    setWindowAttribute(vim.window, 'focus-type', focusType)
  )

  # Setup the public API. See public.coffee for more information. This is done
  # _after_ the prefs observing setup, so that option prefs get validated and
  # used when calling `vimfx.set()`.
  apiUrl = "#{data.resourceURI.spec}lib/public.js"
  prefs.set('api_url', apiUrl)
  publicScope = Cu.import(apiUrl, {})
  api = createAPI(vimfx)
  publicScope._invokeCallback = (callback) ->
    # Calling `vimfx.createKeyTrees()` after each `vimfx.set()` that modifies a
    # shortcut is absolutely redundant and may make Firefox start slower. Do it
    # once instead.
    skipCreateKeyTrees = true
    callback(api)
    skipCreateKeyTrees = false
    vimfx.createKeyTrees()
  module.onShutdown(-> publicScope._invokeCallbacks = null)

  # Pass the API to add-ons that loaded before VimFx, either because they just
  # happened to do so when Firefox started, or because VimFx was updated (or
  # disabled and then enabled) in the middle of the session. Because of the
  # latter case, `Cu.unload(apiUrl)` is not called on shutdown. Otherwise you’d
  # have to either restart Firefox, or disable and enable every add-on using the
  # API in order for them to take effect again. (`_callbacks` should always
  # exist, but it’s better to be safe than sorry.)
  if publicScope._callbacks?.length > 0
    publicScope._invokeCallback((api) ->
      callback(api) for callback in publicScope._callbacks
      return
    )

  test?(vimfx)

  windows = new WeakSet()
  messageManager.listen('tabCreated', (data, {target: browser}) ->
    # Frame script are run in more places than we need. Tell those not to do
    # anything.
    group = browser.getAttribute('messagemanagergroup')
    return false unless group == 'browsers'

    window = browser.ownerGlobal
    vimfx.addVim(browser)

    unless windows.has(window)
      windows.add(window)
      eventManager = new UIEventManager(vimfx, window)
      eventManager.addListeners(vimfx, window)
      setWindowAttribute(window, 'mode', 'normal')
      setWindowAttribute(window, 'focus-type', null)

    return [__SCRIPT_URI_SPEC__]
  )

  messageManager.load('bootstrap')
