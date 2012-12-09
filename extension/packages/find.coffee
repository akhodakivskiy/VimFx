utils = require 'utils'

CONTAINER_ID = 'VimFxFindContainer'

# Create and inserts into DOM find controls and handlers
injectFind = (document) ->
  # Clean up just in case...
  removeFind document

  container = createFindContainer(document)

  document.documentElement.appendChild container

# Removes find controls from DOM
removeFind = (document) ->
  if div = document.getElementById CONTAINER_ID
    document.documentElement.removeChild div

setFindStr = (document, findStr) ->
  document = document

  span = document.getElementById "VimFxFindSpan"
  span.textContent = "/#{ findStr }"

createFindContainer = (document) ->
  return utils.parseHTML document, """
    <div class="VimFxReset" id="#{ CONTAINER_ID }">
      <span class="VimFxReset" id="VimFxFindSpan">/</span>
    </div>
  """

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
    # Wrap Around is broken... Therefore
    if not success = f()
      # If first search attemp has failed then 
      # reset current selection and try again
      window.getSelection().removeAllRanges()
      success = f()

  return success


exports.injectFind = injectFind
exports.removeFind = removeFind
exports.setFindStr = setFindStr
exports.find       = find
