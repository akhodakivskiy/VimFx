utils = require 'utils'
hints = require 'mode-hints/hints'

exports.mode_hints =
  onEnter: (vim, storage, [ callback ]) ->
    markers = hints.injectHints(vim.window.document)
    if markers.length == 0
      vim.enterNormalMode()
      return
    storage.markers  = markers
    storage.callback = callback

  onInput: (vim, storage, keyStr, event) ->
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
        return false if keyStr not in utils.getHintChars() or event.ctrlKey or event.metaKey
        for marker in markers
          marker.matchHintChar(keyStr)

          if marker.isMatched()
            marker.reward() # Add element features to the bloom filter
            dontEnterNormalMode = callback(marker, markers)
            vim.enterNormalMode()  unless dontEnterNormalMode
            break

    return true

  onEnterNormalMode: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.callback = undefined
