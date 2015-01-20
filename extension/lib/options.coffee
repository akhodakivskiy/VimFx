###
# Copyright Simon Lydell 2013, 2014.
# Copyright Wang Zhuochun 2013.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

utils        = require('./utils')
{ getPref }  = require('./prefs')
help         = require('./help')

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
        command: help.injectHelp.bind(undefined, document, require('./modes'))

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

  module.onShutdown(->
    Services.obs.removeObserver(observer, 'addon-options-displayed')
    Services.obs.removeObserver(observer, 'addon-options-hidden')
  )

exports.observe = observe
