utils           = require 'utils'
{ getCommand }  = require 'commands'
{ Vim }         = require 'vim'

{ interfaces: Ci } = Components

KeyboardEvent = Ci.nsIDOMKeyEvent

vimBucket = new utils.Bucket utils.getWindowId, (obj) -> new Vim obj

class KeyInfo
  constructor: (event) ->
    if event.charCode > 0
      @key    = String.fromCharCode(event.charCode)
    else
      switch event.keyCode
        when KeyboardEvent.DOM_VK_ESCAPE  then @key = 'Esc'
        when KeyboardEvent.DOM_VK_TAB     then @key = 'Tab'

    @shift  = event.shiftKey
    @alt    = event.altKey
    @ctrl   = event.ctrlKey
    @meta   = event.metaKey

  isValid: -> @key

  toString: ->
    k = (a, b) -> if a then b else ''
    if @at or @ctrl or @meta
      "<#{ k(@ctrl, 'c') }#{ k(@alt, 'a') }#{ k(@meta, 'm') }-#{ @key }>"
    else
      @key

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

handlers = 
  'keypress': (event) ->
    try
      isEditable =  utils.isElementEditable event.originalTarget
      if event.keyCode == KeyboardEvent.DOM_VK_ESCAPE or not isEditable
        if window = utils.getEventTabWindow event
          keyInfo = new KeyInfo event
          if keyInfo.isValid()
            console.log event.keyCode, event.which, event.charCode, keyInfo.toString()
            if vimBucket.get(window)?.keypress keyInfo
              suppressEvent event
    catch err
      console.log err


  'focus': (event) ->
    if window = utils.getEventTabWindow event
      vimBucket.get(window)?.focus event.originalTarget

  'blur': (event) ->
    if window = utils.getEventTabWindow event
      vimBucket.get(window)?.blur event.originalTarget

  'TabClose': (event) ->
    if gBrowser = utils.getEventTabBrowser event
      if browser = gBrowser.getBrowserForTab event.originalTarget
        vimBucket.forget browser.contentWindow.wrappedJSObject

  'DOMWindowClose': (event) ->
    if gBrowser = event.originalTarget.gBrowser
      for tab in gBrowser.tabs
        if browser = gBrowser.getBrowserForTab tab
          vimBucket.forget browser.contentWindow.wrappedJSObject

exports.handlers = handlers
