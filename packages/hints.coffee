HINTCHARS = 'asdfghjkl;'

{ interfaces: Ci } = Components
HTMLDocument        = Ci.nsIDOMHTMLDocument

class Marker
  constructor: (@element) ->

class DocumentMarkers
  constroctor: (@document) ->


hasHints = (document) ->
  false
    
addHints = (document, cb) ->
  if document instanceof HTMLDocument
    document

removeHints = (document) ->
  if hasHints document
    null

exports.addHints    = addHints
exports.removeHints = removeHints
exports.hasHints    = removeHints
