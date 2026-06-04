var aliases = {
  "left":    "ArrowLeft",
  "right":   "ArrowRight",
  "up":      "ArrowUp",
  "down":    "ArrowDown",
  "bs":      "Backspace",
  "menu":    "ContextMenu",
  "apps":    "ContextMenu",
  "del":     "Delete",
  "return":  "Enter",
  "cr":      "Enter",
  "esc":     "Escape",
  "pgup":    "PageUp",
  "pgdn":    "PageDown",
  "lt":      "<",
  "less":    "<",
  "lesser":  "<",
  "gt":      ">",
  "greater": ">"
}

var enUsTranslations = {
  "Backquote":    ["`",  "~"],
  "Digit1":       ["1",  "!"],
  "Digit2":       ["2",  "@"],
  "Digit3":       ["3",  "#"],
  "Digit4":       ["4",  "$"],
  "Digit5":       ["5",  "%"],
  "Digit6":       ["6",  "^"],
  "Digit7":       ["7",  "&"],
  "Digit8":       ["8",  "*"],
  "Digit9":       ["9",  "("],
  "Digit0":       ["0",  ")"],
  "Minus":        ["-",  "_"],
  "Equal":        ["=",  "+"],
  "Backslash":    ["\\", "|"],
  "BracketLeft":  ["[",  "{"],
  "BracketRight": ["]",  "}"],
  "Semicolon":    [";",  ":"],
  "Quote":        ["'",  '"'],
  "Comma":        [",",  "<"],
  "Period":       [".",  ">"],
  "Slash":        ["/",  "?"]
}

var modifierMap = {
  "a": "altKey",
  "c": "ctrlKey",
  "m": "metaKey",
  "s": "shiftKey"
}

var specialCases = {
  "<": "lt",
  ">": "gt"
}

var ignored = /^($|Unidentified$|Dead$|Alt|Control|Hyper|Meta|Shift|Super|OS)/


function alias(key) {
  var keyLower = key.toLowerCase()
  if (keyLower in aliases) {
    return aliases[keyLower]
  }
  return key
}

function translate(translations, key, shift) {
  var translation = translations[key]
  if (Array.isArray(translation)) {
    translation = translation[shift ? 1 : 0]
  }
  if (typeof translation !== "string") {
    throw error({
      id:      "bad_translation",
      context: key,
      subject: translation,
      message: "Bad translation value"
    })
  }
  return translation
}

function codeToEnUsQwerty(code, shift) {
  var key = code

  if (/^Key/.test(code)) {
    key = code.slice(3)
    if (!shift) {
      key = key.toLowerCase()
    }
  } else if (code in enUsTranslations) {
    key = translate(enUsTranslations, code, shift)
  }

  return key
}

function error(props) {
  var err = new Error(
    ("context" in props ? props.context + ": " : "") +
    props.message + ": " + props.subject
  )
  err.id      = props.id
  err.context = props.context
  err.subject = props.subject
  return err
}



function stringify(event, options) {
  options = options || {}

  var alt   = event.altKey
  var ctrl  = event.ctrlKey
  var meta  = event.metaKey
  var shift = event.shiftKey

  var key  = event.key  || "Unidentified"
  var code = event.code || ""
  if (options.translations && code in options.translations) {
    key = alias(translate(options.translations, code, shift))
  } else if (
    (options.ignoreKeyboardLayout && !/^Numpad/.test(code)) ||
    key === "Unidentified"
  ) {
    key = codeToEnUsQwerty(code, shift)
  } else {
    key = alias(key)
    if (key === " ") {
      key = "Space"
    }
  }

  if (ignored.test(key)) {
    return ""
  }

  if (key.length === 1) {
    shift = false
  } else {
    key = key.toLowerCase()
  }

  var modifiers = ""
  if (alt)   modifiers += "a-"
  if (ctrl)  modifiers += "c-"
  if (meta)  modifiers += "m-"
  if (shift) modifiers += "s-"

  if (options.ignoreCtrlAlt && modifiers === "a-c-" && key.length === 1) {
    modifiers = ""
  }

  if (key in specialCases) {
    key = specialCases[key]
  }

  if (modifiers || key.length > 1) {
    return "<" + modifiers + key + ">"
  }

  return key
}

function parse(keyString) {
  if (keyString.length === 1) {
    if (/\s/.test(keyString)) {
      throw error({
        id:      "invalid_key",
        subject: keyString,
        message: "Invalid key"
      })
    }
    return {
      key: keyString
    }
  }

  var match = keyString.match(/^<((?:[a-z]-)*)([a-z\d]+|[^<>\s])>$/i)
  if (!match) {
    throw error({
      id:      "invalid_key",
      subject: keyString,
      message: "Invalid key"
    })
  }
  var modifiers = match[1]
  var key       = match[2]

  var obj = {
    key: alias(key)
  }

  modifiers.split("-").slice(0, -1).forEach(function(modifier) {

    var modifierLower = modifier.toLowerCase()
    if (!(modifierLower in modifierMap)) {
      throw error({
        id:      "unknown_modifier",
        context: keyString,
        subject: modifier,
        message: "Unknown modifier"
      })
    }
    var modifierName = modifierMap[modifierLower]

    if (modifierName in obj) {
      throw error({
        id:      "duplicate_modifier",
        context: keyString,
        subject: modifier,
        message: "Duplicate modifier"
      })
    }

    obj[modifierName] = true

    if (obj.key.length === 1 && obj.shiftKey) {
      throw error({
        id:      "disallowed_modifier",
        context: keyString,
        subject: modifier,
        message: "Unusable modifier with single-character keys"
      })
    }
  })

  return obj
}

function normalize(keyString) {
  return stringify(parse(keyString))
}

function parseSequence(keySequence) {
  return keySequence.match(/<[^<>\s]+>|[\s\S]|^$/g)
}

exports.stringify     = stringify
exports.parse         = parse
exports.normalize     = normalize
exports.parseSequence = parseSequence
