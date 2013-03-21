utils = require 'utils'

CONTAINER_ID = 'VimFxFindContainer'

# Create and inserts into DOM find controls and handlers
injectFind = (document) ->
  # Clean up just in case...
  removeFind document

  [div, input] = createFindContainer(document)

  document.documentElement.appendChild div
  input.focus()

# Removes find controls from DOM
removeFind = (document) ->
  if div = document.getElementById CONTAINER_ID
    document.documentElement.removeChild div

flashFind = (document, findStr) ->
  window = document.defaultView

  injectFind document
  setFindStr document, findStr

  window.setTimeout (-> removeFind document), 1000

setFindStr = (document, findStr) ->
  if span = document.getElementById "VimFxFindSpan"
    span.textContent = "/#{ findStr }"

createFindContainer = (document) ->
  div = document.createElement 'div'
  div.className = 'VimFxReset'
  div.id = CONTAINER_ID

  input = document.createElement 'input'
  input.type = 'text'
  input.id = 'VimFxFindInput'
  input.addEventListener 'input', (event) ->
    if rootWindow = utils.getRootWindow event.target.ownerDocument.defaultView
      if fastFind = rootWindow.gBrowser.fastFind 
        result = fastFind.find input.value, false

  input.addEventListener 'blur', (event) ->
    console.log 'find input blur'

  console.log 'creating'
  div.appendChild input

  return [ div, input ]

find = (window, findStr, backwards=false) ->
  f = ->
    smartCase = findStr.toLowerCase() != findStr

    return window.find \
      findStr,
      smartCase,  # Smart case sensitivity
      backwards,  # To avoid getting last search result in the beginning
      true,       # aWrapAround - Doesn't currently work as expected
      false,      # aWholeWord - Not implemented according to MDN
      true,       # aSearchInFrames - Hell yea, search in frames!
      false       # aShowDialog - No dialog please


  success =  false

  # Perform find only if query string isn't empty to avoid find dialog pop up
  if findStr.length > 0
    # This will change the ::selection css rule
    addClass window.document.body, "VimFxFindModeBody"

    # Wrap Around is broken... Therefore
    if not success = f()
      # If first search attemp has failed then 
      # reset current selection and try again
      window.getSelection().removeAllRanges()
      success = f()

    # For now let's rely on the fact that Fiefox doesn't update the selection
    # if the css fule that governs it is chnaged
    window.setTimeout (-> removeClass window.document.body, "VimFxFindModeBody"), 1000

  return success

# Adds a class the the `element.className` trying to keep the whole class string
# will formed (without extra spaces at the tails)
addClass = (element, klass) ->
  if element.className?.search klass == -1
    if element.className 
      element.className += " #{ klass }"
    else
      element.className = klass 

# Remove a class from the `element.className`
removeClass = (element, klass) ->
  name = element.className.replace new RegExp("\\s*#{ klass }"), ""
  element.className = name or null


exports.injectFind = injectFind
exports.removeFind = removeFind
exports.flashFind  = flashFind
exports.setFindStr = setFindStr
exports.find       = find
