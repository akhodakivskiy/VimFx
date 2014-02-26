utils                     = require 'utils'
{ getPref }               = require 'prefs'
{ Marker }                = require 'mode-hints/marker'
{ addHuffmanCodeWordsTo } = require 'mode-hints/huffman'

{ interfaces: Ci } = Components

HTMLDocument = Ci.nsIDOMHTMLDocument
XULDocument  = Ci.nsIDOMXULDocument

CONTAINER_ID  = 'VimFxHintMarkerContainer'
Z_INDEX_START = 100000000 # The highest `z-index` used in style.css plus one

# Remove previously injected hints from the DOM
removeHints = (document) ->
  document.getElementById(CONTAINER_ID)?.remove()

  for frame in document.defaultView.frames
    removeHints(frame.document)


injectHints = (document) ->
  markers = createMarkers(document)
  hintChars = utils.getHintChars()

  # Each marker gets a unique `z-index`, so that it can be determined if a marker overlaps another.
  # Put more important markers (higher weight) at the end, so that they get higher `z-index`, in
  # order not to be overlapped.
  markers.sort((a, b) -> a.weight - b.weight)
  for marker, index in markers
    marker.markerElement.style.setProperty('z-index', Z_INDEX_START + index, 'important')

  addHuffmanCodeWordsTo(markers, {alphabet: hintChars}, (marker, hint) -> marker.setHint(hint))

  removeHints(document)
  insertHints(markers)

  # Must be done after the hints have been inserted into the DOM (see marker.coffee)
  for marker in markers
    marker.completePosition()

  return markers


insertHints = (markers) ->
  docFrags = []

  getFrag = (document) ->
    for [doc, frag] in docFrags
      if document == doc
        return frag

  for marker in markers
    doc = marker.element.ownerDocument
    if not getFrag(doc)
      docFrags.push([doc, doc.createDocumentFragment()])

    frag = getFrag(doc)
    frag.appendChild(marker.markerElement)

  for [doc, frag] in docFrags
    container = createHintsContainer(doc)
    container.appendChild(frag)
    doc.documentElement.appendChild(container)


createMarkers = (document) ->
  # For now we aren't able to handle hint markers in XUL Documents :(
  if document instanceof HTMLDocument # or document instanceof XULDocument
    if document.documentElement
      # Select all markable elements in the document, create markers
      # for each of them, and position them on the page.
      # Note that the markers are not given hints.
      set = utils.getMarkableElements(document, {type: 'all'})
      markers = []
      for element in set
        if rect = getElementRect(element)
          marker = new Marker(element)
          marker.setPosition(rect.top, rect.left)
          marker.weight = rect.area * marker.calcBloomRating()

          markers.push(marker)

      for frame in document.defaultView.frames
        markers = markers.concat(createMarkers(frame.document))

  return markers or []


createHintsContainer = (document) ->
  container = utils.createElement(document, 'div', {id: CONTAINER_ID})
  return container


# Uses `element.getBoundingClientRect()`. If that does not return a visible rectange, then looks at
# the children of the markable node.
#
# The logic has been copied over from Vimiun originally.
getElementRect = (element) ->
  document = element.ownerDocument
  window   = document.defaultView
  docElem  = document.documentElement
  body     = document.body

  return unless utils.isElementVisible(element)

  clientTop  = docElem.clientTop  or body?.clientTop  or 0
  clientLeft = docElem.clientLeft or body?.clientLeft or 0
  scrollTop  = window.pageYOffset or docElem.scrollTop
  scrollLeft = window.pageXOffset or docElem.scrollLeft

  clientRect = element.getBoundingClientRect()

  if isRectOk(clientRect, window)
    return {
      top:    clientRect.top  + scrollTop  - clientTop
      left:   clientRect.left + scrollLeft - clientLeft
      width:  clientRect.width
      height: clientRect.height
      area:   clientRect.width * clientRect.height
    }

  # If the rect has 0 dimensions, then check what's inside.
  # Floated or absolutely positioned elements are of particular interest.
  if clientRect.width is 0 or clientRect.height is 0
    for childElement in element.children
      if computedStyle = window.getComputedStyle(childElement, null)
        if computedStyle.getPropertyValue('float') != 'none' or \
           computedStyle.getPropertyValue('position') == 'absolute'

          return getElementRect(childElement)

  return


# Checks if the given TextRectangle object qualifies
# for its own Marker with respect to the `window` object
isRectOk = (rect, window) ->
  minimum = 2
  rect.width >  minimum and rect.height >  minimum and \
  rect.top   > -minimum and rect.left   > -minimum and \
  rect.top   <  window.innerHeight - minimum and \
  rect.left  <  window.innerWidth  - minimum



# Finds all stacks of markers that overlap each other (by using `getStackFor`) (#1), and rotates
# their `z-index`:es (#2), thus alternating which markers are visible.
rotateOverlappingMarkers = (originalMarkers, forward) ->
  # Shallow working copy. This is necessary since `markers` will be mutated and eventually empty.
  markers = originalMarkers[..]

  # (#1)
  stacks = (getStackFor(markers.pop(), markers) while markers.length > 0)

  # (#2)
  # Stacks of length 1 don't participate in any overlapping, and can therefore be skipped.
  for stack in stacks when stack.length > 1
    # This sort is not required, but makes the rotation more predictable.
    stack.sort((a, b) -> a.markerElement.style.zIndex - b.markerElement.style.zIndex)

    # Array of z-indices
    indexStack = (marker.markerElement.style.zIndex for marker in stack)
    # Shift the array of indices one item forward or back
    if forward
      indexStack.unshift(indexStack.pop())
    else
      indexStack.push(indexStack.shift())

    for marker, index in stack
      marker.markerElement.style.setProperty('z-index', indexStack[index], 'important')

  return

# Get an array containing `marker` and all markers that overlap `marker`, if any, which is called
# a "stack". All markers in the returned stack are spliced out from `markers`, thus mutating it.
getStackFor = (marker, markers) ->
  stack = [marker]

  { top, bottom, left, right } = marker.position

  index = 0
  while index < markers.length
    nextMarker = markers[index]

    { top: nextTop, bottom: nextBottom, left: nextLeft, right: nextRight } = nextMarker.position
    overlapsVertically   = (nextBottom >= top  and nextTop  <= bottom)
    overlapsHorizontally = (nextRight  >= left and nextLeft <= right)

    if overlapsVertically and overlapsHorizontally
      # Also get all markers overlapping this one
      markers.splice(index, 1)
      stack = stack.concat(getStackFor(nextMarker, markers))
    else
      # Continue the search
      index++

  return stack


exports.injectHints = injectHints
exports.removeHints = removeHints
exports.rotateOverlappingMarkers = rotateOverlappingMarkers
