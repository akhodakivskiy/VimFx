HINTCHARS     = 'asdfghjkl;'
CONTAINER_ID  = 'vimffHintMarkerContainer'

{ interfaces: Ci }          = Components
HTMLDocument                = Ci.nsIDOMHTMLDocument
{ Marker, getElementRect }  = require 'marker'

indexToHint = (i, chars) ->
  return '' if i < 0

  n = chars.length
  l = Math.floor(i / n); k = i % n;

  return indexToHint(l - 1, chars) + chars[k]

hintToIndex = (hint, chars) ->
  return -1 if hint.length < 1

  n = chars.length; m = hint.length

  i = chars.indexOf(hint[m - 1])
  if hint.length > 1
    base = hintToIndex(hint.slice(0, m - 1), chars)
    i += (base + 1) * n

  return i

getHintsContainer = (document) ->
  document.getElementById CONTAINER_ID

createHintsContainer = (document) ->
  container = document.createElement 'div'
  container.id = CONTAINER_ID
  return container

hasHints = (document) ->
  document.getUserData 'vimff.has_hints'
    
addHints = (document, cb) ->
  if hasHints document
    removeHints document

  if document instanceof HTMLDocument
    container = createHintsContainer document

    start = new Date().getTime()

    markers = {}; i = 0;
    for link in document.links
      if rect = getElementRect link
        hint = indexToHint(i++, HINTCHARS)
        marker = new Marker(link, container)
        marker.setPosition rect
        marker.setHint hint
        markers[hint] = marker

    console.log new Date().getTime() - start, 'aaaaa'

    document.setUserData 'vimff.has_hints', true, null
    document.setUserData 'vimff.markers', markers, null

    document.body.appendChild container

removeHints = (document) ->
  console.log hasHints document
  if hasHints document
    document.setUserData 'vimff.has_hints', undefined, null
    document.setUserData 'vimff.markers', undefined, null

    document.body.removeChild container if container = getHintsContainer document

exports.addHints    = addHints
exports.removeHints = removeHints
exports.hasHints    = removeHints
