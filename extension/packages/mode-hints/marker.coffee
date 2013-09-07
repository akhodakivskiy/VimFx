{ SerializableBloomFilter
, DummyBloomFilter } = require 'mode-hints/bloomfilter'

{ getPref } = require 'prefs'

HTMLDocument      = Ci.nsIDOMHTMLDocument
HTMLAnchorElement = Ci.nsIDOMHTMLAnchorElement

Z_INDEX_START = 99999999 # The highest `z-index` used in style.css
_zIndex = Z_INDEX_START
# Each marker will get a `z-index` of `_zIndex++`. In theory, `z-index` can be infinitely large. In
# practice, Firefox uses a 32-bit signed integer to store it, so the maximum value is 2147483647
# (http://www.puidokas.com/max-z-index/). However, we do not need to worry about hitting the limit,
# since the user would have to browse through a bit more than 2 billion links in a single Firefox
# session before that happens.

realBloomFilter = new SerializableBloomFilter('hints_bloom_data', 256 * 32, 16)
dummyBloomFilter = new DummyBloomFilter()

# Wraps the markable element and provides methods to manipulate the markers
class Marker
  # Creates the marker DOM node
  constructor: (@element) ->
    document = @element.ownerDocument
    window = document.defaultView
    @markerElement = document.createElement('div')
    @markerElement.className = 'VimFxReset VimFxHintMarker'

    Object.defineProperty this, 'bloomFilter',
      get: -> if getPref('hints_bloom_on') then realBloomFilter else dummyBloomFilter

  show: -> @setVisibility(true)
  hide: -> @setVisibility(false)
  setVisibility: (visible) ->
    method = if visible then 'remove' else 'add'
    @markerElement.classList[method]('VimFxHiddenHintMarker')

  setPosition: (top, left) ->
    # The positioning is absulute
    @markerElement.style.top  = "#{ top }px"
    @markerElement.style.left = "#{ left }px"

    # For quick access
    @position = {top, left}

    # Each marker gets a unique `z-index`, so that it can be determined if a marker overlaps another.
    @markerElement.style.setProperty('z-index', _zIndex++, 'important')

  # To be called when the marker has been both assigned a hint and inserted into the DOM, and thus
  # gotten a height and width.
  completePosition: ->
    {
      position: { top, left }
      markerElement: { offsetHeight: height, offsetWidth: width }
    } = this
    @position = {top, bottom: top + height, left, right: left + width, height, width}

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

    @completePosition()

  matchHintChar: (char) ->
    @updateEnteredHintChars(char)

  deleteHintChar: ->
    @updateEnteredHintChars(false)

  updateEnteredHintChars: (char) ->
    if char == false
      method = 'remove'
      @enteredHintChars = @enteredHintChars[...-1]
      offset = 0
    else
      method = 'add'
      @enteredHintChars += char.toLowerCase()
      offset = -1

    @markerElement.children[@enteredHintChars.length + offset]?.classList[method]('VimFxCharMatch')
    if @hintChars.startsWith(@enteredHintChars) then @show() else @hide()

  isMatched: ->
    return @hintChars == @enteredHintChars

  # Returns string features of the element that can be used in the bloom filter
  # in order to add relevance to the hint marker
  extractBloomFeatures: ->
    features = {}

    # Class name of an element (walks up the node tree to find first element with at least one class)
    suffix = ''
    el = @element
    while el.classList?.length == 0 and el not instanceof HTMLDocument
      suffix += " #{ el.tagName }"
      el = el.parentNode
    if el?.classList?
      for className in el.classList
        features["#{ el.tagName }.#{ className }#{ suffix }"] = 10

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
      rating += if @bloomFilter.test(feature) then weight else 0

    return rating

  reward: ->
    for feature, weight of @extractBloomFeatures()
      @bloomFilter.add(feature)
    @bloomFilter.save()

exports.Marker = Marker
