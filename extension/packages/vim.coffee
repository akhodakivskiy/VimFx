MODE_NORMAL = {}

class Vim
  constructor: ({ @window, @commands, @modes, @esc }) ->
    @mode       = MODE_NORMAL
    @keys       = []
    @lastKeyStr = null
    @suppress   = false

    @storage =
      commands: {}
      modes: {}

    for { name } in @commands
      @storage.commands[name] = {}

    for name of @modes
      @storage.modes[name] = {}

  enterMode: (mode, args) ->
    # Note: `args` is an array of arguments to be passed to the mode's `enter` method. We cannot use
    # `args...`, since that destroys the `this` context for the mode's `enter` method.
    @mode = mode
    @modes[mode].enter(this, @storage.modes[mode], args)

  enterNormalMode: ->
    for name, mode of @modes
      mode.onEnterNormalMode?(this, @storage.modes[name])
    @mode = MODE_NORMAL

  handleKeyDown: (event, @lastKeyStr) ->
    @suppress = true
    @keys.push(@lastKeyStr)
    if @mode == MODE_NORMAL or @lastKeyStr == @esc
      { match, exact, command, index } = @searchForCommand(@keys, @commands)
      if match
        @keys = @keys[index..]
        command.func(this, @storage.commands[command.name])  if exact
        return @lastKeyStr != @esc
    else
      ok = @modes[@mode].handleKeyDown(this, @storage.modes[@mode], event)
      return true if ok

    @suppress = false
    @keys.length = 0
    return false

  handleKeyPress: (event) ->
    return @lastKeyStr != @esc and @suppress

  handleKeyUp: (event) ->
    suppress = @suppress
    @suppress = false
    return @lastKeyStr != @esc and suppress

  # Intentionally taking `keys` and `commands` as parameters (instead of simply using `@keys` and
  # `@commands`), so that the method can be reused by custom modes.
  searchForCommand: (keys, commands) ->
    for index in [0...keys.length] by 1
      str = keys[index..].join(',')
      for command in commands
        for key in command.keys()
          if key.startsWith(str) and command.enabled()
            return {match: true, exact: (key == str), command, index}
    return {match: false}

# What is minimally required for a command
class Vim.Command
  constructor: (@keyValues, @name) ->
  keys: -> return @keyValues
  enabled: -> return true

exports.Vim = Vim
