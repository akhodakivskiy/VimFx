utils        = require 'utils'
{ unloader } = require 'unloader'
{ getPref }  = require 'prefs'
help         = require 'help'
{ commands } = require 'commands'

observe = ->
  Services.obs.addObserver(observer, 'addon-options-displayed', false)
  Services.obs.addObserver(observer, 'addon-options-hidden',    false)

observer =
  observe: (document, topic, addon) ->
    spec =
      'setting[pref="extensions.VimFx.hint_chars"]':
        change: filterChars
      'setting[pref="extensions.VimFx.black_list"]':
        change: utils.updateBlacklist
      'setting[pref="extensions.VimFx.prev_patterns"]':
        change: validatePatterns
      'setting[pref="extensions.VimFx.next_patterns"]':
        change: validatePatterns
      '#customizeButton':
        command: help.injectHelp.bind(undefined, document, commands)

    switch topic
      when 'addon-options-displayed'
        applySpec(document, spec, true)
      when 'addon-options-hidden'
        applySpec(document, spec, false)

filterChars = (event) ->
  input = event.target
  input.value = utils.removeDuplicateCharacters(input.value).replace(/\s/g, '')
  input.valueToPreference()

validatePatterns = (event) ->
  input = event.target
  input.value =
    utils.removeDuplicates(utils.splitListString(input.value))
    .filter((pattern) -> pattern != '')
    .join(',')
  input.valueToPreference()

applySpec = (document, spec, enable) ->
  for selector, events of spec
    element = document.querySelector(selector)
    method = if enable then 'addEventListener' else 'removeEventListener'
    for event, action of events
      element[method](event, action, false)

  unloader.add(->
    Services.obs.removeObserver(observer, 'addon-options-displayed')
    Services.obs.removeObserver(observer, 'addon-options-hidden')
  )

exports.observe = observe
