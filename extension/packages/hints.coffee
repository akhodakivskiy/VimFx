CONTAINER_ID  = 'VimFxHintMarkerContainer'

{ interfaces: Ci }  = Components
HTMLDocument        = Ci.nsIDOMHTMLDocument
XULDocument         = Ci.nsIDOMXULDocument
{ Marker }          = require 'marker'

createHintsContainer = (document) ->
  container = document.createElement 'div'
  container.id = CONTAINER_ID
  container.className = 'VimFxReset'
  return container
    
# Creates and injects hint markers into the DOM
injectHints = (document) ->
  # First remove previous hints container
  removeHints document

  # For now we aren't able to handle hint markers in XUL Documents :(
  if document instanceof HTMLDocument# or document instanceof XULDocument
    if document.documentElement
      # Find and create markers
      markers = Marker.createMarkers document

      container = createHintsContainer document

      # For performance use Document Fragment
      fragment = document.createDocumentFragment()
      for marker in markers
        fragment.appendChild marker.markerElement

      container.appendChild fragment
      document.documentElement.appendChild container

      return markers

# Remove previously injected hints from the DOM
removeHints = (document, markers) ->
  if container = document.getElementById CONTAINER_ID
    document.documentElement.removeChild container 


exports.injectHints     = injectHints
exports.removeHints     = removeHints
