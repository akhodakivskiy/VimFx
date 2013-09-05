utils = require 'utils'
hints = require 'hints'

mode_hints =
  enter: (vim, storage, [ callback ]) ->
    markers = hints.injectHints(vim.window.document)
    if markers.length == 0
      vim.enterNormalMode()
      return
    storage.markers = markers
    storage.callback = callback

  handleKeyDown: (vim, storage, event, keyStr) ->
    if utils.getHintChars().search(utils.regexpEscape(keyStr)) > -1
      @hintCharHandler(vim, storage, keyStr)
      return true

  onEnterNormalMode: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.callback = undefined

  # Processes the char, updates and hides/shows markers
  hintCharHandler: (vim, storage, keyStr) ->
    if keyStr
      # Get char and escape it to avoid problems with String.search
      key = utils.regexpEscape(keyStr)

      { markers, callback } = storage

      # First do a pre match - count how many markers will match with the new character entered
      if markers.reduce(((v, marker) -> v or marker.willMatch(key)), false)
        for marker in markers
          marker.matchHintChar(key)

          if marker.isMatched()
            # Add element features to the bloom filter
            marker.reward()
            callback(marker)
            vim.enterNormalMode()
            break

modes =
  hints: mode_hints

exports.modes = modes
