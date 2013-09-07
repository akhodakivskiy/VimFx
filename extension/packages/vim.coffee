MODE_NORMAL = {}

class Vim
  constructor: ({ @window, @commands, @modes, @esc }) ->
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
    # Note: `args` is an array of arguments to be passed to the mode's `onEnter` method. We cannot
    # use `args...`, since that destroys the `this` context for the mode's `onEnter` method.
    @mode = mode
    @modes[mode].onEnter?(this, @storage.modes[mode], args)

  enterNormalMode: ->
    return if @mode == MODE_NORMAL
    @modes[@mode].onEnterNormalMode?(this, @storage.modes[@mode])
    @mode = MODE_NORMAL
    @keys.length = 0

  onInput: (keyStr, event) ->
    @keys.push(keyStr)

    if @mode == MODE_NORMAL
      { match, exact, command, index } = @searchForCommand(@commands)

      if match
        if exact then command.func(this, @storage.commands[command.name], event)
        return true
      else
        return false

    else
      if keyStr == @esc
        @enterNormalMode()
        return true
      else
        return @modes[@mode].onInput?(this, @storage.modes[@mode], keyStr, event)

  # Intentionally taking `commands` as a parameter (instead of simply using `@commands`), so that
  # the method can be reused by custom modes.
  searchForCommand: (commands) ->
    for index in [0...@keys.length] by 1
      str = @keys[index..].join(',')
      for command in commands
        for key in command.keys()
          if key.startsWith(str) and command.enabled()
            @keys = @keys[index..]
            return {match: true, exact: (key == str), command}

    @keys.length = 0
    return {match: false}

Vim.MODE_NORMAL = MODE_NORMAL

# What is minimally required for a command
class Vim.Command
  constructor: (@name) ->
  keys: -> return ['key1', 'key2', 'keyN']
  enabled: -> return true
  func: (vim, storage, event) ->

exports.Vim = Vim
