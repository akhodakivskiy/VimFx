MODIFIERS = [
  'Shift', 'Control', 'Alt', 'AltGraph', 'Meta', 'Super', 'Hyper', 'OS'
]
LEGACY_VIMFX_SHIFT_KEYCHARS = [
  'Esc', 'Backspace', 'Space', 'Tab', 'Return', 'Left', 'Right', 'Up', 'Down'
]

# This function used to receive `event.keyCode` as the first argument, and then
# try to translate it to a readable “keyChar”. Now it gets `event.key` instead,
# which means that, ideally, no translation should be needed. However, we used
# to call some keys one thing, while `event.key` is something else. To maintain
# backwards compatibility with the users’ customizations, this function is
# kept, trying to behave just like the old one. The only exception is that now
# we allow more keys to be used, since `event.key` recognizes more keys than
# this function used to. At some point we should refactor this function away.
keyCharFromCode = (key, shiftKey = false) ->
  # The function used to return `undefined` if the `keyCode` wasn’t in the
  # allowed set or wasn’t recognized, so let’s keep it that way for now. The
  # only difference is that the allowed set has been changed to anything but
  # modifiers.
  if key in MODIFIERS or key == 'Unidentified'
    return undefined

  # `event.key` calls the space bar “ ” (an actual space character), while we
  # called it “Space”. This translation is sane and should be kept after a
  # refactor.
  if key == ' '
    key = 'Space'

  # `event.key` says “Enter”, we used to say “Return”.
  if key == 'Enter'
    key = 'Return'

  # We used to return for example “Shift-Esc” if shift was held when Esc was
  # pressed. In the future you should be able to use shift with any
  # non-character key (shift with character keys are taken care of
  # automatically by `event.key`).
  if shiftKey and key in LEGACY_VIMFX_SHIFT_KEYCHARS
    key = "Shift-#{ key }"

  return key

# Format keyChar that arrives during `keypress` into keyStr
applyModifiers = (keyChar, ctrlKey = false, altKey = false, metaKey = false) ->
  if not keyChar
    return keyChar

  modifier = ''
  modifier += 'c' if ctrlKey
  modifier += 'm' if metaKey
  modifier += 'a' if altKey

  if modifier.length > 0
    return "#{ modifier }-#{ keyChar }"
  else
    return keyChar

exports.keyCharFromCode = keyCharFromCode
exports.applyModifiers  = applyModifiers
