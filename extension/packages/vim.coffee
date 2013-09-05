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

  handleKeyDown: (event, keyStr) ->
    @suppress = true
    if @mode == MODE_NORMAL or keyStr == @esc
      @keys.push(keyStr)
      @lastKeyStr = keyStr
      if command = @findCommand(@keys)
        command.func(this, @storage.commands[command.name])
        return command.name != @esc
      else if @maybeCommand(@keys)
        return true
      else
        @keys.length = 0
    else if not (event.ctrlKey or event.metaKey)
      return @modes[@mode].handleKeyDown(this, @storage.modes[@mode], event, keyStr)

    @suppress = false
    @keys.length = 0
    return false

  handleKeyPress: (event) ->
    return @lastKeyStr != @esc and @suppress

  handleKeyUp: (event) ->
    suppress = @suppress
    @suppress = false
    return @lastKeyStr != @esc and suppress

  findCommand: (keys) ->
    for i in [0...keys.length]
      str = keys[i..].join(',')
      for command in @commands
        for key in command.keys()
          if key == str and command.enabled()
            return command

  maybeCommand: (keys) ->
    for i in [0...keys.length]
      str = keys[i..].join(',')
      for command in @commands
        for key in command.keys()
          if key.indexOf(str) == 0 and command.enabled()
            return true

# What is minimally required for a command
class Vim.Command
  constructor: (@keyValues, @name) ->
  keys: -> return @keyValues
  enabled: -> return true

exports.Vim = Vim
