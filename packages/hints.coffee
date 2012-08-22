HINTCHARS     = 'asdfghjkl;'
CONTAINER_ID  = 'vimffHintMarkerContainer'

{ interfaces: Ci }          = Components
HTMLDocument                = Ci.nsIDOMHTMLDocument
{ Marker, getElementRect }  = require 'marker'

createOrGetHintsContainer = (document) ->
  if container = document.getElementById CONTAINER_ID
    return container
  else
    container = document.createElement 'div'
    container.id = CONTAINER_ID
    document.body.appendChild container
    return container

hasHints = (document) ->
  document.getUserData 'vimff.has_hints'
    
addHints = (document, cb) ->
  if hasHints document
    removeHints document

  if document instanceof HTMLDocument
    container = createOrGetHintsContainer document

    markers = []
    for link in document.links
      if rect = getElementRect link
        marker = new Marker(link, 'aa', container)
        marker.show()
        marker.setPosition rect.left, rect.top
        markers.push marker

    document.setUserData 'vimff.has_hints', true, null
    document.setUserData 'vimff.markers', markers, null

removeHints = (document) ->
  console.log hasHints document
  if hasHints document
    document.setUserData 'vimff.has_hints', undefined, null
    document.setUserData 'vimff.markers', undefined, null

    container = createOrGetHintsContainer document
    document.body.removeChild container

exports.addHints    = addHints
exports.removeHints = removeHints
exports.hasHints    = removeHints
