utils = require 'utils'
hints = require 'mode-hints/hints'

{ escapeCommand } = require 'commands'

exports.mode_hints =
  onEnter: (vim, storage, callback) ->
    markers = hints.injectHints(vim.window.document)
    if markers.length == 0
      vim.enterMode('normal')
    else
      storage.markers  = markers
      storage.callback = callback

  onLeave: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.callback = undefined

  onKeydown: (vim, storage, event, keyStr) ->
    if keyStr in escapeCommand.keys()
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
        return false if keyStr not in utils.getHintChars() or event.ctrlKey or event.metaKey
        for marker in markers
          marker.matchHintChar(keyStr)

          if marker.isMatched()
            marker.reward() # Add element features to the bloom filter
            dontEnterNormalMode = callback(marker, markers)
            vim.enterMode('normal') unless dontEnterNormalMode
            break

    return true

  onLocationChange: (vim, storage, event) ->
    # If the location changes when in hints mode (for example because the reload button has been
    # clicked), we're going to end up in hints mode without any markers. So switch back to normal
    # mode in that case.
    vim.enterMode('normal')
