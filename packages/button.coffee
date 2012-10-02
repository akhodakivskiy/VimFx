{ getPref 
, setPref } = require 'prefs'

positions = {}

persist = (document, toolbar, buttonID, beforeID) ->
  currentset = tb.getAttribute('currentset').split(',')
  idx = if beforeID then currentset.indexOf(beforeID) else -1;
  if idx != -1
    currentset.splice(idx, 0, buttonID);
  else
    currentset.push(buttonID);

  toolbar.setAttribute "currentset", currentset.join(",")
  document.persist toolbar.id, "currentset"
  return [currentset, idx]

setButtonDefaultPosition = (buttonId, toolbarId, beforeId) ->
  positions[buttonId] = [toolbarId, beforeId]

restorePosition = (doc, button) ->
  $ = (sel, all) -> doc[if all then "querySelectorAll" else "getElementById"](sel)
  
  ($("navigator-toolbox") || $("mail-toolbox")).palette.appendChild(button)
  
  for tb in $("toolbar", true)
    currentset = tb.getAttribute('currentset').split(',')
    idx = currentset.indexOf button.id
    if idx > -1
      toolbar = tb
      break
  
  # Saved position not found, using the default one, after persisting it
  if !toolbar and (button.id in Object.keys(positions))
    [tbID, beforeID] = positions[button.id];
    toolbar = $(tbID)
    [currentset, idx] = persist(doc, toolbar, button.id, beforeID)
  
  if toolbar
    if idx > -1
      # Inserting the button before the first item in `currentset`
      # after `idx` that is present in the document
      for i in [idx + 1 ... currentset.length]
        if before = $(currentset[i])
          toolbar.insertItem button.id, before
          return;

    toolbar.insertItem button.id

iconUrl = do ->
  icon_normal = getResourceURI('resources/icon.png').spec
  icon_grey   = getResourceURI('resources/icon-grey.png').spec

  return (disabled) -> "url(#{ if disabled then icon_grey else icon_normal })"

addToolbarButton = (window) ->
  buttonId = getPref 'button_id'
  disabled = getPref 'disabled'

  doc = window.document
  button = doc.createElement 'toolbarbutton'
  button.setAttribute 'id', buttonId
  button.setAttribute 'type', 'checkbox'
  button.setAttribute 'label', 'Vim for Firefox'
  button.setAttribute 'class', 'toolbarbutton-1 chromeclass-toolbar-additional'
  button.setAttribute 'tooltiptext', 'Enable/Disable'
  button.checked = disabled
  button.style.listStyleImage = iconUrl(disabled)

  onButtonCommand = (event) ->
    dis = button.checked
    setPref 'disabled', dis
    button.style.listStyleImage = iconUrl(dis)

  button.addEventListener 'command', onButtonCommand, false
  

  restorePosition doc, button, 'nav-bar', 'bookmarks-menu-button-container'

  unload -> button.parentNode.removeChild button

exports.addToolbarButton          = addToolbarButton
exports.setButtonDefaultPosition  = setButtonDefaultPosition
