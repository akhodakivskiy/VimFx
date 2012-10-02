"use strict"

console = do ->
  cc = Cc["@mozilla.org/consoleservice;1"].getService(Ci.nsIConsoleService)

  stringify = (arg) ->
    try 
      return String(arg)
    catch error
      return "<toString() error>"

  message = (level, args) ->
    dump "VimFx - #{ level }: #{ Array.map(args, stringify).join(" ") }\n"

  expand = (arg) ->
    if typeof(arg) == 'object'
      keys = Object.keys(arg)
      str = "#{ String(arg) }: #{ keys.length }"
      for key in keys
        str += "\n-\t#{ key }: #{ arg[key] }"

      return str
    else
      return arg

  return {
    log: -> message 'log', arguments
    info: -> message 'info', arguments
    error: -> message 'error', arguments
    warning: -> message 'warning', arguments
    expand: -> message 'expand', Array.map(arguments, expand)
  }
