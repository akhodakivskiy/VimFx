# coffeelint: disable=colon_assignment_spacing
# coffeelint: disable=no_implicit_braces

aliases =
  'left':    'ArrowLeft'
  'right':   'ArrowRight'
  'up':      'ArrowUp'
  'down':    'ArrowDown'
  'bs':      'Backspace'
  'menu':    'ContextMenu'
  'apps':    'ContextMenu'
  'del':     'Delete'
  'return':  'Enter'
  'cr':      'Enter'
  'esc':     'Escape'
  'pgup':    'PageUp'
  'pgdn':    'PageDown'
  'lt':      '<'
  'less':    '<'
  'lesser':  '<'
  'gt':      '>'
  'greater': '>'

enUsTranslations =
  'Backquote':    ['`',  '~']
  'Digit1':       ['1',  '!']
  'Digit2':       ['2',  '@']
  'Digit3':       ['3',  '#']
  'Digit4':       ['4',  '$']
  'Digit5':       ['5',  '%']
  'Digit6':       ['6',  '^']
  'Digit7':       ['7',  '&']
  'Digit8':       ['8',  '*']
  'Digit9':       ['9',  '(']
  'Digit0':       ['0',  ')']
  'Minus':        ['-',  '_']
  'Equal':        ['=',  '+']
  'Backslash':    ['\\', '|']
  'BracketLeft':  ['[',  '{']
  'BracketRight': [']',  '}']
  'Semicolon':    [';',  ':']
  'Quote':        ["'",  '"']
  'Comma':        [',',  '<']
  'Period':       ['.',  '>']
  'Slash':        ['/',  '?']

modifierMap =
  'a': 'altKey'
  'c': 'ctrlKey'
  'm': 'metaKey'
  's': 'shiftKey'

specialCases =
  '<': 'lt'
  '>': 'gt'

# coffeelint: enable=colon_assignment_spacing
# coffeelint: enable=no_implicit_braces

ignored = /^($|Unidentified$|Dead$|Alt|Control|Hyper|Meta|Shift|Super|OS)/


alias = (key) ->
  keyLower = key.toLowerCase()
  if keyLower of aliases
    return aliases[keyLower]
  key

translate = (translations, key, shift) ->
  translation = translations[key]
  if Array.isArray(translation)
    translation = translation[if shift then 1 else 0]
  if typeof translation != 'string'
    throw error({
      id: 'bad_translation'
      context: key
      subject: translation
      message: 'Bad translation value'
    })
  translation

codeToEnUsQwerty = (code, shift) ->
  key = code

  if /^Key/.test(code)
    key = code.slice(3)
    if not shift
      key = key.toLowerCase()
  else if code of enUsTranslations
    key = translate(enUsTranslations, code, shift)

  key

error = (props) ->
  err = new Error(
    (if 'context' of props then "#{props.context}: " else '') +
    "#{props.message}: #{props.subject}"
  )
  err.id      = props.id
  err.context = props.context
  err.subject = props.subject
  err

stringify = (event, options) ->
  options = options or {}

  alt   = event.altKey
  ctrl  = event.ctrlKey
  meta  = event.metaKey
  shift = event.shiftKey

  key  = event.key or 'Unidentified'
  code = event.code or ''
  if options.translations and code of options.translations
    key = alias(translate(options.translations, code, shift))
  else if (options.ignoreKeyboardLayout and not /^Numpad/.test(code)) or
      key == 'Unidentified'
    key = codeToEnUsQwerty(code, shift)
  else
    key = alias(key)
    if key == ' '
      key = 'Space'

  if ignored.test(key)
    return ''

  if key.length == 1
    shift = false
  else
    key = key.toLowerCase()

  modifiers = ''
  modifiers += 'a-' if alt
  modifiers += 'c-' if ctrl
  modifiers += 'm-' if meta
  modifiers += 's-' if shift

  if options.ignoreCtrlAlt and modifiers == 'a-c-' and key.length == 1
    modifiers = ''

  if key of specialCases
    key = specialCases[key]

  if modifiers or key.length > 1
    return '<' + modifiers + key + '>'

  key

parse = (keyString) ->
  if keyString.length == 1
    if /\s/.test(keyString)
      throw error({
        id: 'invalid_key'
        subject: keyString
        message: 'Invalid key'
      })
    return {
      key: keyString
    }

  match = keyString.match(/^<((?:[a-z]-)*)([a-z\d]+|[^<>\s])>$/i)
  if not match
    throw error({
      id: 'invalid_key'
      subject: keyString
      message: 'Invalid key'
    })
  modifiers = match[1]
  key       = match[2]

  obj = {
    key: alias(key)
  }

  modifiers.split('-').slice(0, -1).forEach((modifier) ->

    modifierLower = modifier.toLowerCase()
    if modifierLower not of modifierMap
      throw error({
        id: 'unknown_modifier'
        context: keyString
        subject: modifier
        message: 'Unknown modifier'
      })
    modifierName = modifierMap[modifierLower]

    if modifierName of obj
      throw error({
        id: 'duplicate_modifier'
        context: keyString
        subject: modifier
        message: 'Duplicate modifier'
      })

    obj[modifierName] = true

    if obj.key.length == 1 and obj.shiftKey
      throw error({
        id: 'disallowed_modifier'
        context: keyString
        subject: modifier
        message: 'Unusable modifier with single-character keys'
      })
  )

  obj

normalize = (keyString) ->
  stringify(parse(keyString))

parseSequence = (keySequence) ->
  keySequence.match(/<[^<>\s]+>|[\s\S]|^$/g)

exports.stringify     = stringify
exports.parse         = parse
exports.normalize     = normalize
exports.parseSequence = parseSequence
