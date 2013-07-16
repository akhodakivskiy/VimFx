CONTAINER_ID = 'VimFxFindContainer'
DIRECTION_FORWARDS = 0
DIRECTION_BACKWARDS = 1

# Create and inserts into DOM find controls and handlers
injectFind = (document, cb) ->
  # Clean up just in case...
  removeFind document

  # Create container div insert a text input into it
  [div, input] = createFindContainer(document)

  # Call back in new input
  input.addEventListener 'input', (event) ->
    result = cb(input.value)
    if result
      input.classList.remove 'VimFxNotFound'
    else
      input.classList.add 'VimFxNotFound'

  # Call back on (Shift)-Enter with proper direction
  input.addEventListener 'keypress', (event) ->
    if event.keyCode == event.DOM_VK_RETURN
      focusSelection(document, Ci.nsISelectionController.SELECTION_FIND)
      removeFind(document, false)

  document.documentElement.appendChild div
  input.focus()

# Removes find controls from DOM
removeFind = (document, clear = true) ->
  if div = document.getElementById CONTAINER_ID
    document.documentElement.removeChild div

  if clear
    clearSelection(document.defaultView)

focusSelection = (document, selectionType) ->
  if controller = getController(document.defaultView)
    if selection = controller.getSelection(selectionType)
      if selection.rangeCount > 0
        element = selection.getRangeAt(0).commonAncestorContainer?.parentNode
        if element.focus
          element.focus()

createFindContainer = (document) ->
  div = document.createElement 'div'
  div.className = 'VimFxReset'
  div.id = CONTAINER_ID

  input = document.createElement 'input'
  input.type = 'text'
  input.className = 'VimFxReset'
  input.id = 'VimFxFindInput'

  div.appendChild input

  return [ div, input ]

clearSelection = (window, selectionType = Ci.nsISelectionController.SELECTION_FIND) ->
  for frame in window.frames
    clearSelection(frame)

  if controller = getController(window)
    controller.getSelection(selectionType).removeAllRanges()

findFactory = (selectionType) ->
  finder = Cc["@mozilla.org/embedcomp/rangefind;1"]
              .createInstance()
              .QueryInterface(Components.interfaces.nsIFind)

  return (window, findStr, findRng = null, direction = DIRECTION_FORWARDS, focus = false) ->
    # `find` will also recursively search in all frames.  # `innerFind` does the work:
    # searches, selects, scrolls, and optionally reaches into frames
    innerFind = (window) ->
      if controller = getController(window)
        finder.findBackwards = (direction == DIRECTION_BACKWARDS)
        finder.caseSensitive = (findStr != findStr.toLowerCase())

        searchRange = window.document.createRange()
        searchRange.selectNodeContents window.document.body

        if findRng and findRng.commonAncestorContainer.ownerDocument == window.document
          if finder.findBackwards
            searchRange.setEnd(findRng.startContainer, findRng.startOffset)
          else
            searchRange.setStart(findRng.endContainer, findRng.endOffset)

        (startPt = searchRange.cloneRange()).collapse(true)
        (endPt = searchRange.cloneRange()).collapse(false)

        if finder.findBackwards
          [startPt, endPt] = [endPt, startPt]

        if range = finder.Find(findStr, searchRange, startPt, endPt)
          controller.getSelection(selectionType).addRange(range)
          controller.scrollSelectionIntoView(selectionType, range, Ci.nsISelectionController.SCROLL_CENTER_VERTICALLY)
          if focus
            focusSelection(window.document, selectionType)

          return range

    clearSelection(window, selectionType)

    if findStr.length > 0
      # Get all embedded windows/frames including the passed window
      wnds = getAllWindows window
      # In backward searching reverse windows mode so that
      # it starts off the deepest iframe
      if finder.findBackwards
        wnds.reverse()

      # First search in the same window to which current `findRng` belongs
      if rngWindow = findRng?.commonAncestorContainer.ownerDocument.defaultView
        wnds = cycleToItem wnds, rngWindow

      for w in wnds
        if range = innerFind w
          break

    return if (findStr.length == 0) then true else range

highlightFactory = (selectionType) ->
  finder = Cc["@mozilla.org/embedcomp/rangefind;1"]
              .createInstance()
              .QueryInterface(Components.interfaces.nsIFind)

  return (window, findStr) ->
    matchesCount = 0
    finder.findBackwards = false
    finder.caseSensitive = (findStr != findStr.toLowerCase())

    innerHighlight = (window) ->
      if controller = getController(window)
        searchRange = window.document.createRange()
        searchRange.selectNodeContents window.document.body

        (startPt = searchRange.cloneRange()).collapse(true)
        (endPt = searchRange.cloneRange()).collapse(false)

        selection = controller.getSelection(selectionType)
        while (range = finder.Find(findStr, searchRange, startPt, endPt))
          selection.addRange(range)
          matchesCount += 1
          (startPt = range.cloneRange()).collapse(false)

      # Highlight in iframes
      for frame in window.frames
        innerHighlight(frame)

    clearSelection(window, selectionType)

    if findStr.length > 0
      innerHighlight(window)

    return if (findStr.length == 0) then true else matchesCount

getController = (window) ->
  if not window.innerWidth or not window.innerHeight
    return null

  return window.QueryInterface(Ci.nsIInterfaceRequestor)
               .getInterface(Ci.nsIWebNavigation)
               .QueryInterface(Ci.nsIInterfaceRequestor)
               .getInterface(Ci.nsISelectionDisplay)
               .QueryInterface(Ci.nsISelectionController)

# Returns flat list of frmaes within provided window
getAllWindows = (window) ->
  result = [window]
  for frame in window.frames
    result = result.concat(getAllWindows(frame))

  return result

cycleToItem = (array, item) ->
  if item and array.indexOf(item) != -1
    while array[0] != item
      array.push array.shift()

  return array

exports.injectFind          = injectFind
exports.removeFind          = removeFind
exports.find                = findFactory(Ci.nsISelectionController.SELECTION_FIND)
exports.highlight           = highlightFactory(Ci.nsISelectionController.SELECTION_FIND)
exports.DIRECTION_FORWARDS  = DIRECTION_FORWARDS
exports.DIRECTION_BACKWARDS = DIRECTION_BACKWARDS
