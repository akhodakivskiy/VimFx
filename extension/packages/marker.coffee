{ interfaces: Ci }      = Components
XPathResult             = Ci.nsIDOMXPathResult

{ getPref } = require 'prefs'

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
  "@contenteditable='' or translate(@contenteditable, 'TRUE', 'true')='true'"
]

# All the following elements qualify for their own marker in hints mode
MARKABLE_ELEMENTS = [
  "a"
  "iframe"
  "area[@href]"
  "textarea"
  "button" 
  "select"
  "input[not(@type='hidden' or @disabled or @readonly)]"
  # Zooming in and out images bigger than viewport size
  "img[contains(@class, 'decoded') and (contains(@class, 'overflowing') or contains(@class, 'shrinkToFit'))]"
]


# Marker class wraps the markable element and provides
# methods to manipulate the markers
class Marker
  # Creates the marker DOM node
  constructor: (@element) ->
    document = @element.ownerDocument
    window = document.defaultView
    @markerElement = document.createElement 'div'
    @markerElement.className = 'VimFxReset VimFxHintMarker'

  # Shows the marker
  show: -> @markerElement.className = 'VimFxReset VimFxHintMarker'

  # Hides the marker
  hide: -> @markerElement.className = 'VimFxReset VimFxHiddenHintMarker'

  # Positions the marker on the page. The positioning is absulute
  setPosition: (rect) ->
    @markerElement.style.left = rect.left + 'px'
    @markerElement.style.top  = rect.top  + 'px'

  # Assigns hint string to the marker
  setHint: (@hintChars) ->
    # number of hint chars that have been matched so far
    @enteredHintChars = ''

    document = @element.ownerDocument

    while @markerElement.hasChildNodes()
      @markerElement.removeChild @markedElement.firstChild

    fragment = document.createDocumentFragment()
    for char in @hintChars
      span = document.createElement 'span'
      span.className = 'VimFxReset'
      span.textContent = char.toUpperCase()
      
      fragment.appendChild span

    @markerElement.appendChild fragment

  # Add another char to the `enteredHintString`, 
  # see if it still matches `hintString`, apply classes to
  # the distinct hint characters and show/hide marker when 
  # the entered string partially (not) matches the hint string
  matchHintChar: (char) ->
    # Handle backspace key by removing a previously entered hint char 
    # and resetting its class
    if char == 'Backspace' 
      if @enteredHintChars.length > 0
        @enteredHintChars = @enteredHintChars.slice(0, -1)
        @markerElement.children[@enteredHintChars.length]?.className = 'VimFxReset'
    # Otherwise append hint char and change hint class
    else 
      @markerElement.children[@enteredHintChars.length]?.className = 'VimFxReset VimFxCharMatch'
      @enteredHintChars += char.toLowerCase()

    # If entered hint chars no longer partially match the hint chars 
    # then hide the marker. Othersie show it back
    if @hintChars.search(@enteredHintChars) == 0 then @show() else @hide()

  # Checks if the marker will be matched if the next character entered is `char`
  willMatch: (char) ->
    char == 'Backspace' or @hintChars.search(@enteredHintChars + char.toLowerCase()) == 0

  # Checks if enterd hint chars completely match the hint chars
  isMatched: ->
    return @hintChars == @enteredHintChars


# Selects all markable elements on the page, creates markers
# for each of them The markers are then positioned on the page
#
# The array of markers is returned
Marker.createMarkers = (document, startIndex) ->
  hintChars = getPref('hint_chars').toLowerCase()

  set = getMarkableElements(document)
  markers = [];

  elements = []
  for i in [0...set.snapshotLength] by 1
    e = set.snapshotItem(i)
    if rect = getElementRect e
      elements.push [e, rect]

  elements.sort ([e1, r1], [e2, r2]) ->
    # <a> links should always be on the top. E.g. not links should go down
    e1tagName = e1.tagName.toLowerCase()
    e2tagName = e2.tagName.toLowerCase()
    if e1tagName == 'a' and e2tagName != 'a'
      return 1
    else if e1tagName != 'a' and e2tagName == 'a'
      return -1
    else if r1.area < r2.area
      return -1
    else if r1.area > r2.area
      return 1
    else
      return 0

  # start from the end because the list is sorted in ascending order
  j = elements.length + startIndex - 1
  for [element, rect] in elements
    # Get a hint for an element
    hint = indexToHint(--j, hintChars)
    marker = new Marker(element)
    marker.setPosition rect
    marker.setHint hint
    markers.push(marker)

  return markers

# Function generator that creates a function that 
# returns hint string for supplied numeric index.
indexToHint = do ->
  # Helper function that returns a permutation number `i`
  # of some of the characters in the `chars` agrument
  f = (i, chars) ->
    return '' if i < 0

    n = chars.length
    l = Math.floor(i / n); k = i % n;

    return f(l - 1, chars) + chars[k]

  return (i, chars) ->
    # split the characters into two groups:
    #
    # *  left chars are used for the head
    # *  right chars are used to build the tail
    left = chars[...chars.length / 3]
    right = chars[chars.length / 3...]

    n = Math.floor(i / left.length)
    m = i % left.length
    return f(n - 1, right) + left[m]
      

# Returns elements that qualify for hint markers in hints mode.
# Generates and memoizes an XPath query internally
getMarkableElements = do ->
  # Some preparations done on startup
  elements = Array.concat \
    MARKABLE_ELEMENTS,
    ["*[#{ MARKABLE_ELEMENT_PROPERTIES.join(" or ") }]"]

  xpath = elements.reduce((m, rule) -> 
    m.concat(["//#{ rule }", "//xhtml:#{ rule }"])
  , []).join(' | ')

  namespaceResolver = (namespace) ->
    if (namespace == "xhtml") then "http://www.w3.org/1999/xhtml" else null

  # The actual function that will return the desired elements 
  return (document, resultType = XPathResult.ORDERED_NODE_SNAPSHOT_TYPE) ->
    document.evaluate xpath, document.documentElement, namespaceResolver, resultType, null

# Checks if the given TextRectangle object qualifies 
# for its own Marker with respect to the `window` object
isRectOk = (rect, window) ->
  rect.width > 2 and rect.height > 2 and \
  rect.top > -2 and rect.left > -2 and \
  rect.top < window.innerHeight - 2 and \
  rect.left < window.innerWidth - 2

# Will scan through `element.getClientRects()` and look for 
# the first visible rectange. If there are no visible rectangles, then
# will look at the children of the markable node. 
#
# The logic has been copied over from Vimiun
getElementRect = (element) ->
  document = element.ownerDocument
  window   = document.defaultView
  docElem  = document.documentElement
  body     = document.body

  clientTop  = docElem.clientTop  || body?.clientTop  || 0;
  clientLeft = docElem.clientLeft || body?.clientLeft || 0;
  scrollTop  = window.pageYOffset || docElem.scrollTop;
  scrollLeft = window.pageXOffset || docElem.scrollLeft;
  
  clientRect = element.getBoundingClientRect()
  rects = [rect for rect in element.getClientRects()]
  rects.push clientRect 

  for rect in rects
    if isRectOk rect, window
      return {
        top:    rect.top  + scrollTop  - clientTop
        left:   rect.left + scrollLeft - clientLeft
        width:  rect.width
        height: rect.height
        area: clientRect.width * clientRect.height
      }

  # If the element has 0 dimentions then check what's inside.
  # Floated or absolutely positioned elements are of particular interest
  for rect in rects
    if rect.width == 0 or rect.height == 0
      for childElement in element.children
        if computedStyle = window.getComputedStyle childElement, null
          if computedStyle.getPropertyValue('float') != 'none' or \
             computedStyle.getPropertyValue('position') == 'absolute'

            return childRect if childRect = getElementRect childElement

  return undefined

exports.Marker = Marker
