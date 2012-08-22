class Marker
  constructor: (@element, @container) ->
    document = @element.ownerDocument
    window = document.defaultView
    @markerElement = document.createElement 'div'
    @markerElement.className = 'vimffReset vimffHintMarker'

    @container.appendChild @markerElement

  show: -> @markerElement.style.display = 'none'
  hide: -> delete @markerElement.style.display

  setPosition: (rect) ->
    @markerElement.style.left = rect.left + 'px'
    @markerElement.style.top  = rect.top  + 'px'

  setHint: (@hint) ->
    document = @element.ownerDocument

    while @markerElement.hasChildNodes()
      @markerElement.removeChild @markedElement.firstChild

    for char in @hint
      span = document.createElement 'span'
      span.className = 'vimffReset'
      span.textContent = char.toUpperCase()
      
      @markerElement.appendChild span


# The login in this method is copied from Vimium for Chrome
getElementRect = (element) ->
  document = element.ownerDocument
  window   = document.defaultView
  docElem  = document.documentElement
  body     = document.body

  clientTop  = docElem.clientTop  || body.clientTop  || 0;
  clientLeft = docElem.clientLeft || body.clientLeft || 0;
  scrollTop  = window.pageYOffset || docElem.scrollTop;
  scrollLeft = window.pageXOffset || docElem.scrollLeft;

  rects = [rect for rect in element.getClientRects()]
  rects.push element.getBoundingClientRect()

  for rect in rects
    if rect.width > 2 and rect.height > 2 and \
       rect.top > -2 and rect.left > -2 and \
       rect.top < window.innerHeight - 2 and \
       rect.left < window.innerWidth - 2

      return {
        top:    rect.top  + scrollTop  - clientTop;
        left:   rect.left + scrollLeft - clientLeft;
        width:  rect.width
        height: rect.height
      }

  # If the element has 0 dimentions then check what's inside.
  # Floated or absolutely positioned elements are of particular interest
  for rect in rects
    if rect.width == 0 or rect.height == 0
      for childElement in element.children
        computedStyle = window.getComputedStyle childElement, null
        if computedStyle.getPropertyValue 'float' != 'none' or \
           computedStyle.getPropertyValue 'position' == 'absolute'

          return childRect if childRect = getElementRect childElement

  return undefined

exports.Marker = Marker
exports.getElementRect = getElementRect
