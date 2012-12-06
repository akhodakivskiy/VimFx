CONTAINER_ID  = 'VimFxHintMarkerContainer'

{ interfaces: Ci }  = Components
HTMLDocument        = Ci.nsIDOMHTMLDocument
{ Marker }          = require 'marker'

getHintsContainer = (document) ->
  document.getElementById CONTAINER_ID

createHintsContainer = (document) ->
  container = document.createElement 'div'
  container.id = CONTAINER_ID
  container.className = 'VimFxReset'
  return container
    
injectHints = (document) ->
  removeHints document

  if document instanceof HTMLDocument and document.documentElement
    markers = Marker.createMarkers document

    container = createHintsContainer document

    fragment = document.createDocumentFragment()
    for marker in markers
      fragment.appendChild marker.markerElement

    container.appendChild fragment

    document.documentElement.appendChild container

    return markers

removeHints = (document, markers) ->
  if container = getHintsContainer document
    document.documentElement.removeChild container 

handleHintChar = (markers, char) ->

exports.injectHints     = injectHints
exports.removeHints     = removeHints
exports.handleHintChar  = handleHintChar
