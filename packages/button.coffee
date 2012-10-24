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

$ = (doc, sel, all) -> doc[if all then "querySelectorAll" else "getElementById"](sel)

restorePosition = (doc, button) ->
  
  ($(doc, "navigator-toolbox") || $(doc, "mail-toolbox")).palette.appendChild(button)
  
  for tb in $(doc, "toolbar", true)
    currentset = tb.getAttribute('currentset').split(',')
    idx = currentset.indexOf button.id
    if idx > -1
      toolbar = tb
      break
  
  # Saved position not found, using the default one, after persisting it
  if !toolbar and (button.id in Object.keys(positions))
    [tbID, beforeID] = positions[button.id];
    toolbar = $(doc, tbID)
    [currentset, idx] = persist(doc, toolbar, button.id, beforeID)
  
  if toolbar
    if idx > -1
      # Inserting the button before the first item in `currentset`
      # after `idx` that is present in the document
      for i in [idx + 1 ... currentset.length]
        if before = $(doc, currentset[i])
          toolbar.insertItem button.id, before
          return;

    toolbar.insertItem button.id

iconUrl = do ->
  kinds = 
    normal:       getResourceURI('resources/icon16.png').spec
    disabled:     getResourceURI('resources/icon16-grey.png').spec
    blacklisted:  getResourceURI('resources/icon16-red.png').spec

  return (kind) -> "url(#{ kinds[kind] })"

addToolbarButton = (window) ->
  disabled = getPref 'disabled'

  doc = window.document
  button = doc.createElement 'toolbarbutton'
  button.setAttribute 'id', getPref 'button_id'
  button.setAttribute 'type', 'checkbox'
  button.setAttribute 'label', getPref 'button_label'
  button.setAttribute 'class', 'toolbarbutton-1 chromeclass-toolbar-additional'
  button.setAttribute 'tooltiptext', getPref 'button_tooltip'
  button.checked = disabled
  button.style.listStyleImage = iconUrl(if disabled then 'disabled' else 'normal')

  onButtonCommand = (event) ->
    dis = button.checked
    setPref 'disabled', dis
    button.style.listStyleImage = iconUrl(if dis then 'disabled' else 'normal')

  button.addEventListener 'command', onButtonCommand, false
  

  restorePosition doc, button, 'nav-bar', 'bookmarks-menu-button-container'

  unload -> button.parentNode.removeChild button

setToolbarButtonMark = (window, mark) ->
  button = $(window.document, getPref 'button_id')
  try
    if mark == 'normal'
      button.disabled = false
      disabled = getPref 'disabled'
      button.style.listStyleImage = iconUrl(if disabled then 'disabled' else 'normal')
      button.setAttribute 'tooltiptext', getPref 'button_tooltip'
    else if mark == 'blacklisted'
      button.disabled = true
      button.style.listStyleImage = iconUrl('blacklisted')
      button.setAttribute 'tooltiptext', getPref 'button_blacklisted_tooltip'
  catch err
    console.log err


exports.addToolbarButton          = addToolbarButton
exports.setToolbarButtonMark      = setToolbarButtonMark 
exports.setButtonDefaultPosition  = setButtonDefaultPosition
