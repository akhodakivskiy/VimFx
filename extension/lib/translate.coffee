# This file provides a simple function for getting the localized version of a
# string of text.

PROPERTIES_FILE = 'vimfx.properties'

stringBundle = Services.strings.createBundle(
  # Randomize URI to work around bug 719376.
  "#{ADDON_PATH}/locale/#{PROPERTIES_FILE}?#{Math.random()}"
)

translate = (name, values...) ->
  try
    return stringBundle.formatStringFromName(name, values, values.length)
  catch error
    # If you accidentally pass a `name` that does not exist in a '.properties'
    # file the thrown error is terrible. It only tells you that an error
    # occurred, but not why. Wrap in a try-catch to fix that.
    console.error('VimFx: Translation error', name, values, error)

module.exports = translate
