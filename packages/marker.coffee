class Marker
  constructor: (@element, @chars, @container) ->
    document = @element.ownerDocument
    window = document.defaultView
    @markerElement = document.createElement 'div'
    @markerElement.className = 'vimffReset vimffHintMarker'
    for char in @chars
      span = document.createElement 'span'
      span.className = 'vimffReset'
      span.textContent = char
      
      @markerElement.appendChild span

  show: -> @container.appendChild @markerElement
  hide: -> @container.removeChild @markerElement

  setPosition: (left, top) ->
    @markerElement.style.left = left + 'px'
    @markerElement.style.top = top + 'px'

getElementRect = (element) ->
  document = element.ownerDocument
  window   = document.defaultView
  docElem  = document.documentElement
  body     = document.body

  rect = element.getBoundingClientRect()

  if rect.width > 0 and rect.height > 0
    clientTop  = docElem.clientTop  || body.clientTop  || 0;
    clientLeft = docElem.clientLeft || body.clientLeft || 0;
    scrollTop  = window.pageYOffset || docElem.scrollTop;
    scrollLeft = window.pageXOffset || docElem.scrollLeft;

    return {
      top:    rect.top  + scrollTop  - clientTop;
      left:   rect.left + scrollLeft - clientLeft;
      width:  rect.width
      height: rect.height
    }

exports.Marker = Marker
exports.getElementRect = getElementRect
