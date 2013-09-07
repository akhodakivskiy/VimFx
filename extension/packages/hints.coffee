utils                     = require 'utils'
{ getPref }               = require 'prefs'
{ Marker }                = require 'marker'
{ addHuffmanCodeWordsTo } = require 'huffman'

{ interfaces: Ci } = Components

HTMLDocument      = Ci.nsIDOMHTMLDocument
XULDocument       = Ci.nsIDOMXULDocument
XPathResult       = Ci.nsIDOMXPathResult

CONTAINER_ID = 'VimFxHintMarkerContainer'

# All the following elements qualify for their own marker in hints mode
MARKABLE_ELEMENTS = [
  "a"
  "iframe"
  "area[@href]"
  "textarea"
  "button"
  "select"
  "input[not(@type='hidden' or @disabled or @readonly)]"
  "embed"
  "object"
]

# All elements that have one or more of the following properties
# qualify for their own marker in hints mode
MARKABLE_ELEMENT_PROPERTIES = [
  "@tabindex"
  "@onclick"
  "@onmousedown"
  "@onmouseup"
  "@oncommand"
  "@role='link'"
  "@role='button'"
  "contains(@class, 'button')"
  "contains(@class, 'js-new-tweets-bar')"
  "@contenteditable='' or translate(@contenteditable, 'TRUE', 'true')='true'"
  # Zooming in and out images bigger than viewport size
  "img[contains(@class, 'decoded') and (contains(@class, 'overflowing') or contains(@class, 'shrinkToFit'))]"
]


# Remove previously injected hints from the DOM
removeHints = (document) ->
  if container = document.getElementById(CONTAINER_ID)
    document.documentElement.removeChild(container)

  for frame in document.defaultView.frames
    removeHints(frame.document)


# Like `injectMarkers`, but also sets hints for the markers
injectHints = (document) ->
  markers = createMarkers(document)
  hintChars = utils.getHintChars()

  addHuffmanCodeWordsTo(markers, {alphabet: hintChars}, (marker, hint) -> marker.setHint(hint))

  removeHints(document)
  insertHints(markers)

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


# Creates and injects markers into the DOM
createMarkers = (document) ->
  # For now we aren't able to handle hint markers in XUL Documents :(
  if document instanceof HTMLDocument# or document instanceof XULDocument
    if document.documentElement
      # Select all markable elements in the document, create markers
      # for each of them, and position them on the page.
      # Note that the markers are not given hints.
      set = getMarkableElements(document)
      markers = []
      for i in [0...set.snapshotLength] by 1
        element = set.snapshotItem(i)
        if rect = getElementRect(element)
          marker = new Marker(element)
          marker.setPosition(rect.top, rect.left)
          marker.weight = rect.area * marker.calcBloomRating()

          markers.push(marker)

      for frame in document.defaultView.frames
        markers = markers.concat(createMarkers(frame.document))

  return markers or []


createHintsContainer = (document) ->
  container = document.createElement('div')
  container.id = CONTAINER_ID
  container.className = 'VimFxReset'
  return container


# Returns elements that qualify for hint markers in hints mode.
# Generates and memoizes an XPath query internally
getMarkableElements = do ->
  # Some preparations done on startup
  elements = [
    MARKABLE_ELEMENTS...
    "*[#{ MARKABLE_ELEMENT_PROPERTIES.join(' or ') }]"
  ]

  reduce = (m, rule) -> m.concat(["//#{ rule }", "//xhtml:#{ rule }"])
  xpath = elements.reduce(reduce, []).join(' | ')

  namespaceResolver = (namespace) ->
    if namespace == 'xhtml' then 'http://www.w3.org/1999/xhtml' else null

  # The actual function that will return the desired elements
  return (document, resultType = XPathResult.ORDERED_NODE_SNAPSHOT_TYPE) ->
    return document.evaluate(xpath, document.documentElement, namespaceResolver, resultType, null)


# Uses `element.getBoundingClientRect()`. If that does not return a visible rectange, then looks at
# the children of the markable node.
#
# The logic has been copied over from Vimiun originally.
getElementRect = (element) ->
  document = element.ownerDocument
  window   = document.defaultView
  docElem  = document.documentElement
  body     = document.body

  # Prune elements that aren't visible on the page
  computedStyle = window.getComputedStyle(element, null)
  if computedStyle
    if computedStyle.getPropertyValue('visibility') != 'visible' or \
       computedStyle.getPropertyValue('display') == 'none' or \
       computedStyle.getPropertyValue('opacity') == '0'
      return

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


exports.injectHints = injectHints
exports.removeHints = removeHints
