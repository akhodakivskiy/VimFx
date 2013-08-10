{ classes: Cc, interfaces: Ci } = Components

console = do ->
  cs = Cc['@mozilla.org/consoleservice;1'].getService(Ci.nsIConsoleService)

  stringify = (arg) ->
    try
      return String(arg)
    catch error
      return '<toString() error>'

  message = (level, args) ->
    str = "VimFx - #{ level }: #{ Array.map(args, stringify).join(' ') }\n"
    dump(str)
    cs.logStringMessage(str)

  expand = (arg) ->
    if typeof(arg) == 'object'
      str = stringify(arg)
      for key, value of arg
        str += "\n-\t#{ key }: #{ value }"
      return str
    else
      return arg

  return {
    log:     -> message('log',     arguments)
    info:    -> message('info',    arguments)
    error:   -> message('error',   arguments)
    warning: -> message('warning', arguments)
    expand:  -> message('expand',  Array.map(arguments, expand))
  }

exports.console = console
