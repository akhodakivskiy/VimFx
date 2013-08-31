utils = require 'utils'
hints = require 'hints'

mode_hints =
  enter: (vim, storage, markers, cb) ->
    storage.markers = markers
    storage.cb = cb

  handleKeyDown: (vim, storage, event, keyStr) ->
    if utils.getHintChars().search(utils.regexpEscape(keyStr)) > -1
      @hintCharHandler(vim, storage, keyStr)
      return true

  # Processes the char, updates and hides/shows markers
  hintCharHandler: (vim, storage, keyStr) ->
    if keyStr
      # Get char and escape it to avoid problems with String.search
      key = utils.regexpEscape(keyStr)

      { markers, cb } = storage

      # First do a pre match - count how many markers will match with the new character entered
      if markers.reduce(((v, marker) -> v or marker.willMatch(key)), false)
        for marker in markers
          marker.matchHintChar(key)

          if marker.isMatched()
            # Add element features to the bloom filter
            marker.reward()
            cb(marker)
            vim.enterNormalMode()
            break

  onEnterNormalMode: (vim, storage) ->
    hints.removeHints(vim.window.document)
    storage.markers = storage.cb = undefined

modes =
  hints: mode_hints

exports.modes = modes
