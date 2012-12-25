{ getPref 
, setPref } = require 'prefs'

{ injectHelp } = require 'help'
{ commandsHelp } = require 'commands'

utils = require 'utils'

KEYSET_ID             = 'vimfx-keyset'
BUTTON_ID             = 'vimfx-toolbar-button'
KEY_ID                = 'vimfx-key'
MENUPOPUP_ID          = 'vimfx-menupopup'
MENU_ITEM_PREF        = 'vimfx-menu-item-preferences'
MENU_ITEM_HELP        = 'vimfx-menu-item-help'
TEXTBOX_BLACKLIST_ID  = 'vimfx-textbox-blacklist-id'
BUTTON_BLACKLIST_ID   = 'vimfx-button-blacklist-id'

$ = (doc, sel) -> doc.getElementById(sel)
$$ = (doc, sel) -> doc.querySelectorAll(sel)

positions = {}

setButtonInstallPosition = (toolbarId, beforeId) ->
  positions[BUTTON_ID] = [toolbarId, beforeId]

persist = (document, toolbar, buttonId, beforeId) ->
  currentset = toolbar.currentSet.split ','
  idx = if beforeId then currentset.indexOf(beforeId) else -1
  if idx != -1
    currentset.splice(idx, 0, buttonId);
  else
    currentset.push(buttonId);

  toolbar.setAttribute "currentset", currentset.join ','
  document.persist toolbar.id, "currentset"
  return [currentset, idx]

restorePosition = (doc, button) ->
  $(doc, "navigator-toolbox").palette.appendChild(button)
  
  for tb in $$(doc, "toolbar")
    currentset = tb.getAttribute("currentset").split ','
    idx = currentset.indexOf button.id
    if idx != -1
      toolbar = tb
      break
  
  # Saved position not found, using the default one, after persisting it
  if !toolbar and pos = positions[button.id]
    [tbID, beforeId] = pos
    if toolbar = $(doc, tbID)
      [currentset, idx] = persist(doc, toolbar, button.id, beforeId)
  
  if toolbar and idx != -1
    # Inserting the button before the first item in `currentset`
    # after `idx` that is present in the document
    for i in [idx + 1 ... currentset.length]
      if before = $(doc, currentset[i])
        toolbar.insertItem button.id, before
        return

    toolbar.insertItem button.id

iconUrl = do ->
  kinds = 
    normal:    getResourceURI('resources/icon16.png').spec
    grey:      getResourceURI('resources/icon16-grey.png').spec
    red:       getResourceURI('resources/icon16-red.png').spec
    blacklist: getResourceURI('resources/icon16-blacklist.png').spec

  return (kind) -> "url(#{ kinds[kind] })"


createMenupopup = (window) ->
  doc = window.document

  blacklistTextbox = doc.createElement 'textbox'
  blacklistTextbox.id = TEXTBOX_BLACKLIST_ID
  blacklistButton = doc.createElement 'toolbarbutton'
  blacklistButton.id = BUTTON_BLACKLIST_ID
  blacklistButton.setAttribute 'tooltiptext', _('item_blacklist_button_tooltip')
  blacklistButton.setAttribute 'class', 'toolbarbutton-1'
  blacklistButton.style.listStyleImage = iconUrl('blacklist')
  hbox = doc.createElement 'hbox'
  hbox.appendChild blacklistTextbox
  hbox.appendChild blacklistButton

  itemPreferences = doc.createElement 'menuitem'
  itemPreferences.id = MENU_ITEM_PREF  
  itemPreferences.setAttribute 'label', _('item_preferences')

  itemHelp = doc.createElement 'menuitem'
  itemHelp.id = MENU_ITEM_HELP  
  itemHelp.setAttribute 'label', _('item_help')

  menupopup = doc.createElement 'menupopup'
  menupopup.id = MENUPOPUP_ID
  menupopup.setAttribute 'ignorekeys', true
  menupopup.appendChild hbox
  menupopup.appendChild itemPreferences
  menupopup.appendChild itemHelp

  onPopupShowing = (event) ->
    if tabWindow = window.gBrowser.selectedTab.linkedBrowser.contentWindow
      blacklistTextbox.value = "*#{ tabWindow.location.host }*"

  onBlacklistButtonCommand = (event) ->
    blackList = getPref 'black_list'
    blackList += ', ' if blackList.length > 0 
    blackList += blacklistTextbox.value

    setPref 'black_list', blackList
    menupopup.hidePopup()

    if tabWindow = window.gBrowser.selectedTab.linkedBrowser.contentWindow
      tabWindow.location.reload(false)

    event.stopPropagation()

  onPreferencesCommand = (event) ->
    id = encodeURIComponent getPref('addon_id')
    window.BrowserOpenAddonsMgr("addons://detail/#{ id }/preferences")

    event.stopPropagation()

  onHelpCommand = (event) ->
    if tabWindow = window.gBrowser.selectedTab.linkedBrowser.contentWindow
      injectHelp tabWindow.document, commandsHelp

    event.stopPropagation()

  menupopup.addEventListener        'popupshowing', onPopupShowing,           false
  blacklistButton.addEventListener  'command',      onBlacklistButtonCommand, false
  itemPreferences.addEventListener  'command',      onPreferencesCommand,     false
  itemHelp.addEventListener         'command',      onHelpCommand,            false

  return menupopup

createButton = (window) ->
  doc = window.document

  button = doc.createElement 'toolbarbutton'
  button.setAttribute 'id', BUTTON_ID
  button.setAttribute 'type', 'menu-button'
  button.setAttribute 'label', 'VimFx'
  button.setAttribute 'class', 'toolbarbutton-1'
  #
  # Create and install event listeners 
  onButtonCommand = (event) ->
    # Change disabled state value which is stored in Prefs
    setPref('disabled', not getPref 'disabled')
    updateToolbarButton button
    
    event.stopPropagation()

  button.addEventListener 'command', onButtonCommand, false

  menupopup = createMenupopup window
  button.appendChild menupopup

  vimkey = doc.createElement 'key'
  vimkey.setAttribute "id", KEY_ID
  vimkey.setAttribute "key", "V"
  vimkey.setAttribute "modifiers", "shift,alt"
  vimkey.setAttribute "oncommand", "void(0);"
  vimkey.addEventListener "command", onButtonCommand, false

  keyset = doc.createElement 'keyset'
  keyset.setAttribute 'id', KEYSET_ID
  keyset.appendChild(vimkey)

  return [button, keyset]

addToolbarButton = (window) ->
  doc = window.document
  win = doc.querySelector 'window'

  [button, keyset] = createButton window
  updateToolbarButton button

  restorePosition doc, button
  win.appendChild keyset

  unload -> 
    if buttonParent = button.parentNode
      buttonParent.removeChild button
    if keysetParent = keyset.parentNode
      keysetParent.removeChild keyset
    $(doc, "navigator-toolbox").palette.removeChild(button)

updateToolbarButton = (button) ->
  if getPref 'disabled'
    button.style.listStyleImage = iconUrl('grey')
    button.setAttribute 'tooltiptext', _('button_tooltip_disabled')
  else if button['VimFx_blacklisted']
    button.style.listStyleImage = iconUrl('red')
    button.setAttribute 'tooltiptext', _('button_tooltip_blacklisted')
  else
    button.style.listStyleImage = iconUrl('normal')
    button.setAttribute 'tooltiptext', _('button_tooltip_enabled')

setWindowBlacklisted = (window, blacklisted) ->
  if button = $(window.document, BUTTON_ID)
    button['VimFx_blacklisted'] = blacklisted
    updateToolbarButton button

exports.addToolbarButton         = addToolbarButton
exports.setWindowBlacklisted     = setWindowBlacklisted 
exports.setButtonInstallPosition = setButtonInstallPosition
