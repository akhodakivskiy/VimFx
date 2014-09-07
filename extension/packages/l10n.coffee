PROPERTIES_FILE = 'vimfx.properties'

# Randomize URI to work around bug 719376.
stringBundle = Services.strings.createBundle(
  "chrome://vimfx/locale/#{ PROPERTIES_FILE }?#{ Math.random() }"
)

_ = (name, values...) ->
  return stringBundle.formatStringFromName(name, values, values.length)

exports._ = _
