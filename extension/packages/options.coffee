utils        = require 'utils'
{ unload }   = require 'unload'
{ getPref }  = require 'prefs'
help         = require 'help'
{ commands } = require 'commands'
{ unload }  = require 'unload'
{ getPref } = require 'prefs'

observer =
  observe: (document, topic, addon) ->
    return unless addon == getPref('addon_id')

    hintCharsInput = document.querySelector('setting[pref="extensions.VimFx.hint_chars"]')
    hintCharsCheckbox = document.querySelector('setting[pref="extensions.VimFx.hint_chars_ignore_case"]')
    blacklistInput = document.querySelector('setting[pref="extensions.VimFx.black_list"]')

    customizeButton = document.getElementById('customizeButton')
    injectHelp = help.injectHelp.bind(undefined, document, commands)

    lastHintChars = undefined

    filterChars = (event) ->
      hintCharsInput.value = utils.removeDuplicateCharacters(hintCharsInput.value).replace(/\s/g, '')
      hintCharsInput.valueToPreference()
      if event
        lastHintChars = hintCharsInput.value

    toUpperCase = ->
      if getPref('hint_chars_ignore_case')
        hintCharsInput.value = hintCharsInput.value.toUpperCase()

    reflectIgnoreCase = ->
      if lastHintChars
        hintCharsInput.value = lastHintChars
      toUpperCase()
      filterChars()

    switch topic
      when 'addon-options-displayed'
        hintCharsInput.addEventListener('change', filterChars, false)
        hintCharsInput.addEventListener('input', toUpperCase, false)
        hintCharsCheckbox.addEventListener('command', reflectIgnoreCase, false)
        blacklistInput.addEventListener('change', utils.updateBlacklist, false)
        customizeButton.addEventListener('command', injectHelp, false)

      when 'addon-options-hidden'
        hintCharsInput.removeEventListener('change', filterChars, false)
        hintCharsInput.removeEventListener('input', filterCharsFoo, false)
        hintCharsCheckbox.removeEventListener('command', reflectIgnoreCase, false)
        blacklistInput.removeEventListener('change', utils.updateBlacklist, false)
        customizeButton.removeEventListener('command', injectHelp, false)

observe = ->
  Services.obs.addObserver(observer, 'addon-options-displayed', false)
  Services.obs.addObserver(observer, 'addon-options-hidden',    false)

  unload ->
    Services.obs.removeObserver(observer, 'addon-options-displayed')
    Services.obs.removeObserver(observer, 'addon-options-hidden')

exports.observe = observe
