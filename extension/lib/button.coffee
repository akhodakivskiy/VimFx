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

{ getPref
, setPref }    = require('./prefs')
{ injectHelp } = require('./help')
utils          = require('./utils')
_              = require('./l10n')

BUTTON_ID             = 'vimfx-toolbar-button'
MENUPOPUP_ID          = 'vimfx-menupopup'
MENU_ITEM_PREF        = 'vimfx-menu-item-preferences'
MENU_ITEM_HELP        = 'vimfx-menu-item-help'
TEXTBOX_BLACKLIST_ID  = 'vimfx-textbox-blacklist-id'
BUTTON_BLACKLIST_ID   = 'vimfx-button-blacklist-id'

$  = (document, selector) -> document.getElementById(selector)
$$ = (document, selector) -> document.querySelectorAll(selector)

positions = {}

setButtonInstallPosition = (toolbarId, beforeId) ->
  positions[BUTTON_ID] = {toolbarId, beforeId}

addToolbarButton = (vimBucket, window) ->
  document = window.document
  win = document.querySelector('window')

  button = createButton(vimBucket, window)

  # Namespace to put the VimFx state on, for example.
  button.VimFx = {}

  restorePosition(document, button)

  if tabWindow = utils.getCurrentTabWindow(window)
    blacklisted = utils.isBlacklisted(tabWindow.location.href)
  disabled = getPref('disabled')
  updateToolbarButton(window, {disabled, blacklisted})

  module.onShutdown(->
    button.remove()
    $(document, 'navigator-toolbox').palette.removeChild(button)
  )

createButton = (vimBucket, window) ->
  document = window.document

  button = utils.createElement(document, 'toolbarbutton', {
    id: BUTTON_ID
    type: 'menu-button'
    label: 'VimFx'
    class: 'toolbarbutton-1'
  })

  menupopup = createMenupopup(window, button)

  onButtonCommand = (event) ->
    switch
      when button.VimFx.blacklisted
        menupopup.openPopup(button, 'after_start')
      when button.VimFx.insertMode
        return unless currentTabWindow = utils.getEventCurrentTabWindow(event)
        return unless vim = vimBucket.get(currentTabWindow)
        updateToolbarButton(window, {insertMode: false})
        vim.enterMode('normal')
      else
        disabled = not getPref('disabled')
        setPref('disabled', disabled)
        updateToolbarButton(window, {disabled})

    event.stopPropagation()

  button.addEventListener('command', onButtonCommand, false)

  return button

createMenupopup = (window, button) ->
  document = window.document

  blacklistTextbox = utils.createElement(document, 'textbox', {
    id: TEXTBOX_BLACKLIST_ID
  })
  blacklistButton  = utils.createElement(document, 'toolbarbutton', {
    id: BUTTON_BLACKLIST_ID
    class: 'toolbarbutton-1'
  })
  blacklistControls = utils.createElement(document, 'hbox')
  blacklistControls.appendChild(blacklistTextbox)
  blacklistControls.appendChild(blacklistButton)

  itemPreferences = utils.createElement(document, 'menuitem', {
    id: MENU_ITEM_PREF
    label: _('item_preferences')
  })

  itemHelp = utils.createElement(document, 'menuitem', {
    id: MENU_ITEM_HELP
    label: _('help_title')
  })

  menupopup = utils.createElement(document, 'menupopup', {
    id: MENUPOPUP_ID
    ignorekeys: true
  })
  menupopup.appendChild(blacklistControls)
  menupopup.appendChild(itemPreferences)
  menupopup.appendChild(itemHelp)

  onPopupShowing = (event) ->
    return unless tabWindow = utils.getCurrentTabWindow(window)

    if button.VimFx.blacklisted
      matchingRules = utils.getMatchingBlacklistRules(tabWindow.location.href)
      blacklistTextbox.value = matchingRules.join(', ')
      blacklistTextbox.setAttribute('readonly', true)
      blacklistButton.setAttribute('tooltiptext',
                                   _('item_blacklist_button_inverse_tooltip'))
      blacklistButton.style.listStyleImage = iconUrl('blacklist_inverse')
    else
      blacklistTextbox.value =
        # In `about:` pages, the `host` property is an empty string. Fall back
        # to the whole URL.
        if tabWindow.location.host != ''
          "*#{ tabWindow.location.host }*"
        else
          tabWindow.location.href
      blacklistTextbox.removeAttribute('readonly')
      blacklistButton.setAttribute('tooltiptext',
                                   _('item_blacklist_button_tooltip'))
      blacklistButton.style.listStyleImage = iconUrl('blacklist')

  onBlacklistButtonCommand = (event) ->
    return unless tabWindow = utils.getCurrentTabWindow(window)

    if button.VimFx.blacklisted
      utils.updateBlacklist({remove: blacklistTextbox.value})
    else
      utils.updateBlacklist({add: blacklistTextbox.value})

    menupopup.hidePopup()

    tabWindow.location.reload(false)

    event.stopPropagation()

  onPreferencesCommand = (event) ->
    id = encodeURIComponent(utils.ADDON_ID)
    window.BrowserOpenAddonsMgr("addons://detail/#{ id }/preferences")

    event.stopPropagation()

  onHelpCommand = (event) ->
    if tabWindow = utils.getCurrentTabWindow(window)
      injectHelp(tabWindow.document, require('./modes'))

    event.stopPropagation()

  menupopup.addEventListener('popupshowing', onPopupShowing, false)
  blacklistButton.addEventListener('command', onBlacklistButtonCommand, false)
  itemPreferences.addEventListener('command', onPreferencesCommand, false)
  itemHelp.addEventListener('command', onHelpCommand, false)

  button.appendChild(menupopup)
  return menupopup

restorePosition = (document, button) ->
  $(document, 'navigator-toolbox').palette.appendChild(button)

  for tb in $$(document, 'toolbar')
    currentset = tb.getAttribute('currentset').split(',')
    idx = currentset.indexOf(button.id)
    if idx != -1
      toolbar = tb
      break

  # Saved position not found, using the default one, after persisting it.
  if not toolbar and button.id of positions
    { toolbarId, beforeId } = positions[button.id]
    if toolbar = $(document, toolbarId)
      [ currentset, idx ] = persist(document, toolbar, button.id, beforeId)

  if toolbar and idx != -1
    # Inserting the button before the first item in `currentset`
    # after `idx` that is present in the document.
    for id in currentset[idx + 1..]
      if before = $(document, id)
        toolbar.insertItem(button.id, before)
        return

    toolbar.insertItem(button.id)

persist = (document, toolbar, buttonId, beforeId) ->
  currentset = toolbar.currentSet.split(',')
  idx = if beforeId then currentset.indexOf(beforeId) else -1
  if idx != -1
    currentset.splice(idx, 0, buttonId)
  else
    currentset.push(buttonId)

  toolbar.setAttribute('currentset', currentset.join(','))
  document.persist(toolbar.id, 'currentset')
  return [currentset, idx]

updateToolbarButton = (window, { disabled, blacklisted, insertMode }) ->
  return unless button = $(window.document, BUTTON_ID)

  button.VimFx.disabled    = disabled     if disabled?
  button.VimFx.blacklisted = blacklisted  if blacklisted?
  button.VimFx.insertMode  = insertMode   if insertMode?

  [ icon, tooltip ] = switch
    when button.VimFx.disabled
      ['grey', 'disabled']
    when button.VimFx.blacklisted
      ['red', 'blacklisted']
    when button.VimFx.insertMode
      ['grey', 'insertMode']
    else
      ['normal', 'enabled']

  button.style.listStyleImage = iconUrl(icon)
  button.setAttribute('tooltiptext', _("button_tooltip_#{ tooltip }"))

iconUrl = (kind) ->
  url = utils.getResourceURI("resources/icon16-#{ kind }.png").spec
  return "url(#{ url })"

exports.setButtonInstallPosition = setButtonInstallPosition
exports.addToolbarButton         = addToolbarButton
exports.updateToolbarButton      = updateToolbarButton
