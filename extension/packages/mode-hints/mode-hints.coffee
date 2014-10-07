utils = require 'utils'
hints = require 'mode-hints/hints'

{ isEscCommandKey } = require 'commands'

exports.mode_hints =
  onEnter: (vim, storage, callback) ->
    markers = hints.injectHints(vim.window)
    if markers?.length > 0
      storage.markers  = markers
      storage.callback = callback
    else
      vim.enterMode('normal')

  onLeave: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.callback = undefined

  onInput: (vim, storage, keyStr, event) ->
    if isEscCommandKey(keyStr)
      vim.enterMode('normal')
      return true

    { markers, callback } = storage

    switch keyStr
      when 'Space'
        hints.rotateOverlappingMarkers(markers, true)
      when 'Shift-Space'
        hints.rotateOverlappingMarkers(markers, false)

      when 'Backspace'
        for marker in markers
          marker.deleteHintChar()

      else
        if keyStr not in utils.getHintChars() or event.ctrlKey or event.metaKey
          return true
        for marker in markers
          marker.matchHintChar(keyStr)

          if marker.isMatched()
            marker.reward() # Add element features to the bloom filter.
            dontEnterNormalMode = callback(marker, markers)
            vim.enterMode('normal') unless dontEnterNormalMode
            break

    return true
