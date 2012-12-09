{ interfaces: Ci } = Components

KE = Ci.nsIDOMKeyEvent

# Extract keyChar from keyCode taking into account the shift modifier
keyCharFromCode = (keyCode, shiftKey=false) ->
  keyChar = undefined
  if keyCode >= KE.DOM_VK_A and keyCode <= KE.DOM_VK_Z
    keyChar = String.fromCharCode(keyCode)
    if shiftKey 
      keyChar = keyChar.toUpperCase()
    else
      keyChar = keyChar.toLowerCase()
  else
    fn = (code, codeWithShift, char, charWithShift) ->
      if keyCode == code
        return if shiftKey then charWithShift else char 
      else if keyCode == codeWithShift
        return charWithShift

    options = [
      [ KE.DOM_VK_ESCAPE,         KE.DOM_VK_ESCAPE,     'Esc',       'Shift-Esc'        ],
      [ KE.DOM_VK_BACK_SPACE,     KE.DOM_VK_BACK_SPACE, 'Backspace', 'Shift-Backspace'  ],
      [ KE.DOM_VK_SPACE,          KE.DOM_VK_SPACE,      'Space',     'Shift-Space'      ],
      [ KE.DOM_VK_TAB,            KE.DOM_VK_TAB,        'Tab',       'Shift-Tab'        ],
      [ KE.DOM_VK_RETURN,         KE.DOM_VK_RETURN,     'Return',    'Shift-Return'     ],

      [ KE.DOM_VK_1,              KE.DOM_VK_EXCLAMATION,          '1',  '!' ],
      [ KE.DOM_VK_2,              KE.DOM_VK_AT,                   '2',  '@' ],
      [ KE.DOM_VK_3,              KE.DOM_VK_HASH,                 '3',  '#' ],
      [ KE.DOM_VK_4,              KE.DOM_VK_DOLLAR,               '4',  '$' ],
      [ KE.DOM_VK_5,              KE.DOM_VK_PERCENT,              '5',  '%' ],
      [ KE.DOM_VK_6,              KE.DOM_VK_CIRCUMFLEX,           '6',  '^' ],
      [ KE.DOM_VK_7,              KE.DOM_VK_AMPERSAND,            '7',  '&' ],
      [ KE.DOM_VK_8,              KE.DOM_VK_ASTERISK,             '8',  '*' ],
      [ KE.DOM_VK_9,              KE.DOM_VK_OPEN_PAREN,           '9',  '(' ],
      [ KE.DOM_VK_0,              KE.DOM_VK_CLOSE_PAREN,          '0',  ')' ],

      [ KE.DOM_VK_OPEN_BRACKET,   KE.DOM_VK_OPEN_CURLY_BRACKET,   '[',  '{' ],
      [ KE.DOM_VK_CLOSE_BRACKET,  KE.DOM_VK_CLOSE_CURLY_BRACKET,  ']',  '}' ],
      [ KE.DOM_VK_SEMICOLON,      KE.DOM_VK_COLON,                ';',  ':' ],
      [ KE.DOM_VK_QUOTE,          KE.DOM_VK_DOUBLEQUOTE,          "'",  '"' ],
      [ KE.DOM_VK_BACK_QUOTE,     KE.DOM_VK_TILDE,                "`",  '~' ],
      [ KE.DOM_VK_BACK_SLASH,     KE.DOM_VK_PIPE,                 "\\", '|' ],
      [ KE.DOM_VK_COMMA,          KE.DOM_VK_LESS_THAN,            ',',  '<' ],
      [ KE.DOM_VK_PERIOD,         KE.DOM_VK_GREATER_THAN,         '.',  '>' ],
      [ KE.DOM_VK_SLASH,          KE.DOM_VK_QUESTION_MARK,        '/',  '?' ],
      [ KE.DOM_VK_HYPHEN_MINUS,   KE.DOM_VK_UNDERSCORE,           '-',  '_' ],
      [ KE.DOM_VK_EQUALS,         KE.DOM_VK_PLUS,                 '=',  '+' ],
    ]

    for opt in options
      if char = fn.apply(undefined, opt)
        keyChar = char
        break

  return keyChar

# Format keyChar that arrives during `keypress` into keyStr
applyModifiers = (keyChar, ctrlKey=false, altKey=false, metaKey=false) ->
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
