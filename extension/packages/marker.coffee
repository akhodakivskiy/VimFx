{ SerializableBloomFilter } = require 'bloomfilter'

HTMLDocument      = Ci.nsIDOMHTMLDocument
HTMLAnchorElement = Ci.nsIDOMHTMLAnchorElement

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

  # Returns string features of the element that can be used in the bloom filter
  # in order to add relevance to the hint marker
  extractBloomFeatures: ->
    features = {}

    # Class name of an element (walks up the node tree to find first element with at least one class)
    suffix = ''
    el = @element
    while el.classList?.length == 0 and not el instanceof HTMLDocument
      suffix = "#{ suffix } #{ el.tagName }"
      el = el.parentNode
    for className in el.classList
      features["#{ el.tagName }.#{ className }#{ suffix }"] = 10

    # Element id
    if @element.id
      features["#{ el.tagName }.#{ @element.id }"] = 5

    if @element instanceof HTMLAnchorElement
      features["a"] = 20 # Reward links no matter what
      features["#{ el.tagName }.#{ @element.href }"] = 60
      features["#{ el.tagName }.#{ @element.title }"] = 40

    return features

  # Returns rating of all present bloom features (plus 1)
  calcBloomRating: ->
    rating = 1
    for feature, weight of @extractBloomFeatures()
      rating += if Marker.bloomFilter.test(feature) then weight else 0

    return rating

  reward: ->
    for feature, weight of @extractBloomFeatures()
      Marker.bloomFilter.add(feature)
    Marker.bloomFilter.save()

Marker.bloomFilter = new SerializableBloomFilter('hint_bloom_data', 256 * 32, 16)

exports.Marker = Marker
