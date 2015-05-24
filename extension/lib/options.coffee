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

utils    = require('./utils')
defaults = require('./defaults')
help     = require('./help')
_        = require('./l10n')

observe = (options) ->
  observer = new Observer(defaults, validators, options)
  observer.hooks.injectSettings = setupCustomizeButton

  Services.obs.addObserver(observer, 'addon-options-displayed', false)
  Services.obs.addObserver(observer, 'addon-options-hidden',    false)

  module.onShutdown(->
    Services.obs.removeObserver(observer, 'addon-options-displayed')
    Services.obs.removeObserver(observer, 'addon-options-hidden')
  )

class Observer
  constructor: (@defaults, @validators, @options) ->
    @document  = null
    @container = null
    @listeners = []
    @hooks     = {}

  useCapture: false

  listen: (element, event, action) ->
    element.addEventListener(event, action, @useCapture)
    @listeners.push([element, event, action, @useCapture])

  unlisten: ->
    for [element, event, action, useCapture] in @listeners
      element.removeEventListener(event, action, useCapture)
    @listeners.length = 0

  typeMap:
    string:  'string'
    number:  'integer'
    boolean: 'bool'

  injectSettings: ->
    @container = @document.getElementById('detail-rows')

    for key, value of @defaults.options
      desc = _("pref_#{ key }_desc")
      if typeof value == 'string' and value != ''
        desc += "\n#{ _('prefs_default', value) }"
      setting = utils.createElement(@document, 'setting', {
        pref:  "#{ @defaults.BRANCH }#{ key }"
        type:  @typeMap[typeof value]
        title: _("pref_#{ key }_title")
        desc:  desc.trim()
      })
      @listen(setting, 'change', @validators[key]) if key of @validators
      @container.appendChild(setting)

    @hooks.injectSettings?.call(this)

    @container.querySelector('setting').setAttribute('first-row', 'true')

  observe: (@document, topic, addonId) ->
    return unless addonId == @options.ID
    switch topic
      when 'addon-options-displayed'
        @injectSettings()
      when 'addon-options-hidden'
        @unlisten()

setupCustomizeButton = ->
  shortcuts = utils.createElement(@document, 'setting', {
    type: 'control',
    title: _('prefs_customize_shortcuts_title')
  })
  button = utils.createElement(@document, 'button', {
    label: _('prefs_customize_shortcuts_label')
  })
  shortcuts.appendChild(button)
  @listen(button, 'command',
          help.injectHelp.bind(undefined, @document, @options))
  @container.appendChild(shortcuts)

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

validators =
  'hint_chars':    filterChars
  'black_list':    utils.updateBlacklist
  'prev_patterns': validatePatterns
  'next_patterns': validatePatterns

exports.observe = observe
