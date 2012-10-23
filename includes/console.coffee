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
      str = stringify(arg)
      for key, value of arg
        str += "\n-\t#{ key }: #{ value }"

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
