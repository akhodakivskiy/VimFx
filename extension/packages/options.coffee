{ removeDuplicateCharacters } = require 'utils'
{ unload }   = require 'unload'
{ getPref }  = require 'prefs'
help         = require 'help'
{ commands } = require 'commands'

observer =
  observe: (document, topic, addon) ->
    return unless addon == getPref('addon_id')

    hintCharsInput = document.querySelector('setting[pref="extensions.VimFx.hint_chars"]')

    customizeButton = document.getElementById('customizeButton')
    injectHelp = help.injectHelp.bind(undefined, document, commands)

    switch topic
      when 'addon-options-displayed'
        hintCharsInput.addEventListener('change', filterChars, false)
        customizeButton.addEventListener('command', injectHelp, false)
      when 'addon-options-hidden'
        hintCharsInput.removeEventListener('change', filterChars, false)
        customizeButton.removeEventListener('command', injectHelp, false)

filterChars = (event) ->
  input = event.target
  input.value = removeDuplicateCharacters(input.value).replace(/\s/g, '')
  input.valueToPreference()

observe = ->
  Services.obs.addObserver(observer, 'addon-options-displayed', false)
  Services.obs.addObserver(observer, 'addon-options-hidden',    false)

  unload ->
    Services.obs.removeObserver(observer, 'addon-options-displayed')
    Services.obs.removeObserver(observer, 'addon-options-hidden')

exports.observe = observe
