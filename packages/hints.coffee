CONTAINER_ID  = 'vimffHintMarkerContainer'

{ interfaces: Ci }  = Components
HTMLDocument        = Ci.nsIDOMHTMLDocument
{ Marker }          = require 'marker'

getHintsContainer = (document) ->
  document.getElementById CONTAINER_ID

createHintsContainer = (document) ->
  container = document.createElement 'div'
  container.id = CONTAINER_ID
  container.className = 'vimffReset'
  return container
    
injectHints = (document) ->
  removeHints document

  if document instanceof HTMLDocument
    markers = Marker.createMarkers document

    container = createHintsContainer document

    fragment = document.createDocumentFragment()
    for marker in markers
      fragment.appendChild marker.markerElement

    container.appendChild fragment

    document.body.appendChild container

    return markers

removeHints = (document, markers) ->
  if container = getHintsContainer document
    document.body.removeChild container 

handleHintChar = (markers, char) ->

exports.injectHints     = injectHints
exports.removeHints     = removeHints
exports.handleHintChar  = handleHintChar
