# Marker class wraps the markable element and provides
# methods to manipulate the markers
class Marker
  # Creates the marker DOM node
  constructor: (@element) ->
    document = @element.ownerDocument
    window = document.defaultView
    @markerElement = document.createElement('div')
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
    # Hint chars that have been matched so far
    @enteredHintChars = ''

    document = @element.ownerDocument

    while @markerElement.hasChildNodes()
      @markerElement.removeChild(@markerElement.firstChild)

    fragment = document.createDocumentFragment()
    for char in @hintChars
      span = document.createElement('span')
      span.className = 'VimFxReset'
      span.textContent = char.toUpperCase()
      fragment.appendChild(span)

    @markerElement.appendChild(fragment)

  # Add another char to the `enteredHintString`,
  # see if it still matches `hintString`, apply classes to
  # the distinct hint characters and show/hide marker when
  # the entered string partially (not) matches the hint string
  matchHintChar: (char) ->
    # Handle backspace key by removing a previously entered hint char
    # and resetting its class
    if char == 'Backspace'
      if @enteredHintChars.length > 0
        @enteredHintChars = @enteredHintChars[0...-1]
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


exports.Marker = Marker
