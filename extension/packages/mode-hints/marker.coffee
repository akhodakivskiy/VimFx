{ createElement }    = require 'utils'
{ SerializableBloomFilter
, DummyBloomFilter } = require 'mode-hints/bloomfilter'

{ getPref } = require 'prefs'

HTMLDocument      = Ci.nsIDOMHTMLDocument
HTMLAnchorElement = Ci.nsIDOMHTMLAnchorElement

realBloomFilter = new SerializableBloomFilter('hints_bloom_data', 256 * 32, 16)
dummyBloomFilter = new DummyBloomFilter()

# Wraps the markable element and provides methods to manipulate the markers
class Marker
  # Creates the marker DOM node
  constructor: (@element, @elementShape) ->
    document = @element.ownerDocument
    @markerElement = createElement(document, 'div', {class: 'VimFxHintMarker'})

    Object.defineProperty this, 'bloomFilter',
      get: -> if getPref('hints_bloom_on') then realBloomFilter else dummyBloomFilter

  show: -> @setVisibility(true)
  hide: -> @setVisibility(false)
  setVisibility: (visible) ->
    @markerElement.classList.toggle('VimFxHiddenHintMarker', !visible)
  updateVisibility: ->
    if @hintChars.startsWith(@enteredHintChars) then @show() else @hide()

  # To be called when the marker has been both assigned a hint and inserted
  # into the DOM, and thus gotten a height and width
  setPosition: (viewport) ->
    {
      markerElement: { offsetHeight: height, offsetWidth: width }
      elementShape: { nonCoveredPoint: { x, y } }
    } = this

    # Make sure that the hint isn’t partly off-screen
    x = Math.min(x, viewport.width  - width)
    y = Math.min(y, viewport.height - height)

    left = viewport.scrollX + x
    top  = viewport.scrollY + y

    # The positioning is absolute
    @markerElement.style.left = "#{ left }px"
    @markerElement.style.top  = "#{ top }px"

    # For quick access
    @position = {left, right: left + width, top, bottom: top + height, height, width}

  setHint: (@hintChars) ->
    # Hint chars that have been matched so far
    @enteredHintChars = ''

    document = @element.ownerDocument

    while @markerElement.hasChildNodes()
      @markerElement.firstChild.remove()

    fragment = document.createDocumentFragment()
    for char in @hintChars
      charContainer = createElement(document, 'span')
      charContainer.textContent = char.toUpperCase()
      fragment.appendChild(charContainer)

    @markerElement.appendChild(fragment)

  matchHintChar: (char) ->
    @toggleLastHintChar(true)
    @enteredHintChars += char.toLowerCase()
    @updateVisibility()

  deleteHintChar: ->
    @enteredHintChars = @enteredHintChars[...-1]
    @toggleLastHintChar(false)
    @updateVisibility()

  toggleLastHintChar: (visible) ->
    @markerElement.children[@enteredHintChars.length]?.classList.toggle('VimFxCharMatch', visible)

  isMatched: ->
    return @hintChars == @enteredHintChars

  reset: ->
    @setHint(@hintChars)
    @show()

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
