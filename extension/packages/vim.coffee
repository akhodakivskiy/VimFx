MODE_NORMAL = {}

class Vim
  constructor: ({ @window, @commands, @modes, @escapeCommand }) ->
    @mode       = MODE_NORMAL
    @keys       = []

    @storage =
      commands: {}
      modes: {}

    for { name } in @commands
      @storage.commands[name] = {}

    for name of @modes
      @storage.modes[name] = {}

  enterMode: (mode, args) ->
    # `args` is an array of arguments to be passed to the mode's `onEnter` method
    @mode = mode
    @modes[mode].onEnter?(this, @storage.modes[mode], args)

  enterNormalMode: ->
    return if @mode == MODE_NORMAL
    @modes[@mode].onEnterNormalMode?(this, @storage.modes[@mode])
    @mode = MODE_NORMAL
    @keys.length = 0

  onInput: (keyStr, event, options = {}) ->
    @keys.push(keyStr)

    esc = @searchForMatchingCommand([@escapeCommand]).exact

    if options.autoInsertMode and not esc
      return false

    if @mode == MODE_NORMAL
      if esc
        return @runCommand(@escapeCommand, event)

      { match, exact, command, index } = @searchForMatchingCommand(@commands)

      if match
        @keys = @keys[index..]
        if exact then @runCommand(command, event)
        return true
      else
        @keys.length = 0
        return false

    else
      if esc
        @enterNormalMode()
        return true
      else
        return @modes[@mode].onInput?(this, @storage.modes[@mode], keyStr, event)

  # Intentionally taking `commands` as a parameter (instead of simply using `@commands`), so that
  # the method can be reused by custom modes (and by escape handling).
  searchForMatchingCommand: (commands) ->
    for index in [0...@keys.length] by 1
      str = @keys[index..].join(',')
      for command in commands
        for key in command.keys()
          if key.startsWith(str) and command.enabled()
            return {match: true, exact: (key == str), command, index}

    return {match: false}

  runCommand: (command, event) ->
    command.func(this, @storage.commands[command.name], event)

Vim.MODE_NORMAL = MODE_NORMAL

# What is minimally required for a command
class Vim.Command
  constructor: (@name) ->
  keys: -> return ['key1', 'key2', 'keyN']
  enabled: -> return true
  func: (vim, storage, event) ->

exports.Vim = Vim
