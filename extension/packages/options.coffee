{ removeDuplicateCharacters } = require 'utils'
{ unload }  = require 'unload'
{ getPref } = require 'prefs'

observer =
  observe: (document, topic, addon) ->
    return unless addon == getPref('addon_id')
    hintCharsInput = document.querySelector('setting[pref="extensions.VimFx.hint_chars"]')
    switch topic
      when 'addon-options-displayed'
        hintCharsInput.addEventListener('change', filterChars, false)
      when 'addon-options-hidden'
        hintCharsInput.removeEventListener('change', filterChars, false)

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
