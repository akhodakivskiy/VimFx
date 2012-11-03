{ getPref 
, setPref } = require 'prefs'

{ showHelp } = require 'help'
{ commandsHelp } = require 'commands'

positions = {}

persist = (document, toolbar, buttonID, beforeID) ->
  currentset = toolbar.getAttribute('currentset').split(',')
  idx = if beforeID then currentset.indexOf(beforeID) else -1
  if idx != -1
    currentset.splice(idx, 0, buttonID);
  else
    currentset.push(buttonID);

  toolbar.setAttribute "currentset", currentset.join(",")
  document.persist toolbar.id, "currentset"
  return [currentset, idx]

setButtonDefaultPosition = (buttonId, toolbarId, beforeId) ->
  positions[buttonId] = [toolbarId, beforeId]

$ = (doc, sel) -> doc.getElementById(sel)
$$ = (doc, sel) -> doc.querySelectorAll(sel)

restorePosition = (doc, button) ->
  $(doc, "navigator-toolbox").palette.appendChild(button)
  
  for tb in $$(doc, "toolbar")
    currentset = tb.getAttribute('currentset').split ','
    idx = currentset.indexOf button.id
    if idx != -1
      toolbar = tb
      break
  
  # Saved position not found, using the default one, after persisting it
  if !toolbar and pos = positions[button.id]
    [tbID, beforeID] = pos
    if toolbar = $(doc, tbID)
      [currentset, idx] = persist(doc, toolbar, button.id, beforeID)
  
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
  blacklistButton = doc.createElement 'toolbarbutton'
  blacklistButton.setAttribute 'tooltiptext', 'Blacklist'
  blacklistButton.setAttribute 'class', 'toolbarbutton-1'
  blacklistButton.style.listStyleImage = iconUrl('blacklist')
  hbox = doc.createElement 'hbox'
  hbox.appendChild blacklistTextbox
  hbox.appendChild blacklistButton

  itemPreferences = doc.createElement 'menuitem'
  itemPreferences.setAttribute 'label', 'Preferences'

  itemHelp = doc.createElement 'menuitem'
  itemHelp.setAttribute 'label', 'Help'

  menupopup = doc.createElement 'menupopup'
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
      showHelp tabWindow.document, commandsHelp

    event.stopPropagation()

  menupopup.addEventListener        'popupshowing', onPopupShowing,           false
  blacklistButton.addEventListener  'command',      onBlacklistButtonCommand, false
  itemPreferences.addEventListener  'command',      onPreferencesCommand,     false
  itemHelp.addEventListener         'command',      onHelpCommand,            false

  return menupopup

createButton = (window) ->
  doc = window.document

  button = doc.createElement 'toolbarbutton'
  button.setAttribute 'id', getPref 'button_id'
  button.setAttribute 'type', 'menu-button'
  button.setAttribute 'label', 'VimFx'
  button.setAttribute 'class', 'toolbarbutton-1'
  #
  # Create and install event listeners 
  onButtonCommand = (event) ->
    # Change disabled state value which is stored in Prefs
    setPref('disabled', not getPref 'disabled')
    updateToolbarButton button

  button.addEventListener 'command', onButtonCommand, false

  menupopup = createMenupopup window
  button.appendChild menupopup

  return button


addToolbarButton = (window) ->
  doc = window.document

  button = createButton window
  updateToolbarButton button

  restorePosition doc, button, 'nav-bar', 'bookmarks-menu-button-container'

  unload -> 
    if buttonParent = button.parentNode
      buttonParent.removeChild button
    $(doc, "navigator-toolbox").palette.removeChild(button)

updateToolbarButton = (button) ->
  if getPref 'disabled'
    button.style.listStyleImage = iconUrl('grey')
    button.setAttribute 'tooltiptext', 'VimFx is Disabled. Click to Enable'
  else if button['VimFx_blacklisted']
    button.style.listStyleImage = iconUrl('red')
    button.setAttribute 'tooltiptext', 'VimFx is Blacklisted on this Site'
  else
    button.style.listStyleImage = iconUrl('normal')
    button.setAttribute 'tooltiptext', 'VimFx is Enabled. Click to Disable'

setWindowBlacklisted = (window, blacklisted) ->
  if button = $(window.document, getPref 'button_id')
    button['VimFx_blacklisted'] = blacklisted
    updateToolbarButton button

exports.addToolbarButton         = addToolbarButton
exports.setWindowBlacklisted     = setWindowBlacklisted 
exports.setButtonDefaultPosition = setButtonDefaultPosition
