"use strict"

stringify = (arg) ->
  try 
    return String(arg)
  catch error
    return "<toString() error>"

message = (prefix, level, args) ->
  dump("#{ prefix } - #{ level }: #{ Array.map(args, stringify).join(" ") }\n") 

class Console
  constructor: (@prefix='extension') ->

  log: -> message(@prefix, 'log', arguments)
  info: -> message(@prefix, 'info', arguments)
  error: -> message(@prefix, 'error', arguments)
  warning: -> message(@prefix, 'warning', arguments)
  expand: ->
    for arg in arguments
      if typeof(arg) == "object"
        len = Object.keys(arg).length
        for k, v of arg
          @log k, v
      else
        @log arg

exports.Console = Console
