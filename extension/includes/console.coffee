{ classes: Cc, interfaces: Ci } = Components

console = do ->
  cs = Cc["@mozilla.org/consoleservice;1"].getService(Ci.nsIConsoleService)

  stringify = (arg) ->
    try
      return String(arg)
    catch error
      return "<toString() error>"

  message = (level, args) ->
    str = "VimFx - #{ level }: #{ Array.map(args, stringify).join(" ") }\n"
    dump str
    cs.logStringMessage str

  expand = (arg) ->
    if typeof(arg) == 'object'
      str = stringify(arg)
      for key, value of arg
        str += "\n-\t#{ key }: #{ value }"

      return str
    else
      return arg

  stacktrace = ->
    st2 = (f) ->
      if f
        name = f.toString().split('(')[0]
        args = Array.map(f.arguments, stringify).join(", ")
        return st2(f.caller)
          .concat(["#{ name } ( #{ args } )"])
      else
        []
    return st2(arguments.callee.caller)


  return {
    log: -> message 'log', arguments
    info: -> message 'info', arguments
    error: -> message 'error', arguments
    warning: -> message 'warning', arguments
    expand: -> message 'expand', Array.map(arguments, expand)
    stacktrace: -> message 'stacktrace', stacktrace()
  }
