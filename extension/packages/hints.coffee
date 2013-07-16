{ Marker }   = require 'marker'

{ interfaces: Ci } = Components

HTMLDocument = Ci.nsIDOMHTMLDocument
XULDocument  = Ci.nsIDOMXULDocument

CONTAINER_ID = 'VimFxHintMarkerContainer'

createHintsContainer = (document) ->
  container = document.createElement('div')
  container.id = CONTAINER_ID
  container.className = 'VimFxReset'
  return container

# Creates and injects hint markers into the DOM
injectHints = (document) ->

  inner = (document, startIndex = 1) ->
    # First remove previous hints container
    removeHints(document)

    # For now we aren't able to handle hint markers in XUL Documents :(
    if document instanceof HTMLDocument# or document instanceof XULDocument
      if document.documentElement
        # Find and create markers
        markers = Marker.createMarkers(document, startIndex)

        container = createHintsContainer(document)

        # For performance use Document Fragment
        fragment = document.createDocumentFragment()
        for marker in markers
          fragment.appendChild(marker.markerElement)

        container.appendChild(fragment)
        document.documentElement.appendChild(container)

        for frame in document.defaultView.frames
          markers = markers.concat(inner(frame.document, markers.length+1))

        return markers

  return inner(document)

# Remove previously injected hints from the DOM
removeHints = (document) ->
  if container = document.getElementById(CONTAINER_ID)
    document.documentElement.removeChild(container)

  for frame in document.defaultView.frames
    removeHints(frame.document)


exports.injectHints = injectHints
exports.removeHints = removeHints
