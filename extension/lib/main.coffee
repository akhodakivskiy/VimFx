###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
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

button = require('./button')
config = require('./config')
defaults = require('./defaults')
help = require('./help')
{applyMigrations} = require('./legacy')
MarkerContainer = require('./marker-container')
messageManager = require('./message-manager')
migrations = require('./migrations')
modes = require('./modes')
options = require('./options')
parsePref = require('./parse-prefs')
prefs = require('./prefs')
UIEventManager = require('./events')
utils = require('./utils')
VimFx = require('./vimfx')
# @if TESTS
test = require('../test/index')
# @endif

{AddonManager} = Cu.import('resource://gre/modules/AddonManager.jsm', {})

module.exports = (data, reason) ->
  # Set default prefs and apply migrations as early as possible.
  prefs.default.init()
  applyMigrations(migrations)

  parsedOptions = {}
  for pref of defaults.all_options
    parsedOptions[pref] = parsePref(pref)
  vimfx = new VimFx(modes, parsedOptions)
  vimfx.id = data.id
  vimfx.version = data.version
  AddonManager.getAddonByID(vimfx.id, (info) -> vimfx.info = info)

  utils.loadCss("#{ADDON_PATH}/skin/style.css")

  options.observe(vimfx)

  prefs.observe('', (pref) ->
    if pref.startsWith('mode.') or pref.startsWith('custom.')
      vimfx.createKeyTrees()
    else if pref of defaults.all_options
      value = parsePref(pref)
      vimfx.options[pref] = value
  )

  button.injectButton(vimfx)

  setWindowAttribute = (window, name, value) ->
    window.document.documentElement.setAttribute("vimfx-#{name}", value)

  onModeDisplayChange = (data) ->
    window = data.vim?.window ? data.event.originalTarget.ownerGlobal

    # The 'modeChange' event provides the `vim` object that changed mode, but
    # it might not be the current `vim` anymore so always get the current one.
    return unless vim = vimfx.getCurrentVim(window)

    setWindowAttribute(window, 'mode', vim.mode)
    vimfx.emit('modeDisplayChange', {vim})

  vimfx.on('modeChange', onModeDisplayChange)
  vimfx.on('TabSelect',  onModeDisplayChange)

  vimfx.on('focusTypeChange', ({vim}) ->
    setWindowAttribute(vim.window, 'focus-type', vim.focusType)
  )

  # `config.load` sends a 'loadConfig' message to all frame scripts, but it is
  # intenionally run _before_ the frame scripts are loaded. Even if it is run
  # after the frame scripts have been `messageManager.load`ed, we cannot know
  # when it is ready to receive messages. Instead, the frame scripts trigger
  # their 'loadConfig' code manually.
  config.load(vimfx)
  vimfx.on('shutdown', -> messageManager.send('unloadConfig'))
  module.onShutdown(->
    # Make sure to run the below lines in this order. The second line results in
    # removing all message listeners in frame scripts, including the one for
    # 'unloadConfig' (see above).
    vimfx.emit('shutdown')
    messageManager.send('shutdown')
  )

  windows = new WeakSet()
  messageManager.listen('tabCreated', (data, callback, browser) ->
    # Frame scripts are run in more places than we need. Tell those not to do
    # anything.
    unless browser.getAttribute('messagemanagergroup') == 'browsers'
      callback(false)
      return

    window = browser.ownerGlobal
    vimfx.addVim(browser)

    unless windows.has(window)
      windows.add(window)
      eventManager = new UIEventManager(vimfx, window)
      eventManager.addListeners(vimfx, window)
      setWindowAttribute(window, 'mode', 'normal')
      setWindowAttribute(window, 'focus-type', 'none')
      module.onShutdown(->
        MarkerContainer.remove(window)
        help.removeHelp(window)
      )

    callback(true)
  )

  # For tabs not visited yet since a session restore (“pending” tabs), Firefox
  # seems to not load the frame script immediately, but instead remember the URI
  # and load it when the user eventually visits that tab. If VimFx is updated
  # during that time this means that the below URI is saved several times, and
  # will be loaded that many times. Therefore the URI is changed with each
  # build, causing remembered URIs to point to non-existent files.
  messageManager.load("#{ADDON_PATH}/content/bootstrap-frame-#{BUILD_TIME}.js")

  # @if TESTS
  test(vimfx)
  runFrameTests = true
  messageManager.listen('runTests', (data, callback) ->
    callback(runFrameTests)
    runFrameTests = false
  )
  # @endif
