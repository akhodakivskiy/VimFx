###
# Copyright Simon Lydell 2015.
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

# This file constructs VimFx’s options UI in the Add-ons Manager.

defaults  = require('./defaults')
translate = require('./l10n')
prefs     = require('./prefs')
utils     = require('./utils')

TYPE_MAP =
  string:  'string'
  number:  'integer'
  boolean: 'bool'

observe = (options) ->
  observer = new Observer(options)
  utils.observe('addon-options-displayed', observer)
  utils.observe('addon-options-hidden',    observer)
  module.onShutdown(->
    observer.destroy()
  )

# Generalized observer.
class BaseObserver
  constructor: (@options) ->
    @document  = null
    @container = null
    @listeners = []

  useCapture: true

  listen: (element, event, action) ->
    element.addEventListener(event, action, @useCapture)
    @listeners.push([element, event, action, @useCapture])

  unlisten: ->
    for [element, event, action, useCapture] in @listeners
      element.removeEventListener(event, action, useCapture)
    @listeners.length = 0

  type: (value) -> TYPE_MAP[typeof value]

  injectSettings: ->

  appendSetting: (attributes) ->
    setting = @document.createElement('setting')
    utils.setAttributes(setting, attributes)
    @container.appendChild(setting)
    return setting

  observe: (@document, topic, addonId) ->
    return unless addonId == @options.id
    switch topic
      when 'addon-options-displayed'
        @init()
      when 'addon-options-hidden'
        @destroy()

  init: ->
    @container = @document.getElementById('detail-rows')
    @injectSettings()

  destroy: ->
    @unlisten()

# VimFx specific observer.
class Observer extends BaseObserver
  constructor: (@vimfx) ->
    super({id: @vimfx.id})

  injectSettings: ->
    @injectInstructions()
    @injectOptions()
    @injectShortcuts()
    @setupKeybindings()
    @setupValidation()

  injectInstructions: ->
    setting = @appendSetting({
      type:  'control'
      title: translate('prefs.instructions.title')
      desc:  translate('prefs.instructions.desc',
               @vimfx.options['options.key.quote'],
               @vimfx.options['options.key.insert_default'],
               @vimfx.options['options.key.reset_default'],
               '<c-z>')
      'first-row': 'true'
    })
    href = "#{@vimfx.info.homepageURL}/tree/master/documentation"
    docsLink = @document.createElement('label')
    utils.setAttributes(docsLink, {
      value: translate('prefs.documentation')
      href
      crop:  'end'
      class: 'text-link'
    })
    setting.appendChild(docsLink)

  injectOptions: ->
    for key, value of defaults.options
      setting = @appendSetting({
        pref:  "#{defaults.BRANCH}#{key}"
        type:  @type(value)
        title: translate("pref.#{key}.title")
        desc:  translate("pref.#{key}.desc")
      })
    return

  injectShortcuts: ->
    for mode in @vimfx.getGroupedCommands()
      @appendSetting({
        type:        'control'
        title:       mode.name
        'first-row': 'true'
      })

      for category in mode.categories
        if category.name
          @appendSetting({
            type:        'control'
            title:       category.name
            'first-row': 'true'
          })

        for {command} in category.commands
          @appendSetting({
            pref:  command.pref
            type:  'string'
            title: command.description()
            desc:  @generateErrorMessage(command.pref)
            class: 'is-shortcut'
          })

    return

  generateErrorMessage: (pref) ->
    commandErrors = @vimfx.errors[pref] ? []
    return commandErrors.map(({id, context, subject}) ->
      return translate("error.#{id}", context ? subject, subject)
    ).join('\n')

  setupKeybindings: ->
    # Note that `setting = event.originalTarget` does _not_ return the correct
    # element in these listeners!
    quote = false
    @listen(@container, 'keydown', (event) =>
      setting = event.target
      isString = (setting.type == 'string')

      {input, pref} = setting
      keyString = @vimfx.stringifyKeyEvent(event)

      # Some shortcuts only make sense for string settings. We still match
      # those shortcuts and suppress the default behavior for _all_ types of
      # settings for consistency. For example, pressing <c-d> in a number input
      # (which looks like a text input) would otherwise bookmark the page, and
      # <c-q> would close the window!
      switch
        when not keyString
          return
        when quote
          break unless isString
          utils.insertText(input, keyString)
          quote = false
        when keyString == @vimfx.options['options.key.quote']
          break unless isString
          quote = true
          # Override `<force>` commands (such as `<escape>` and `<tab>`).
          return unless vim = @vimfx.getCurrentVim(utils.getCurrentWindow())
          @vimfx.modes.normal.commands.quote.run({vim, count: 1})
        when keyString == @vimfx.options['options.key.insert_default']
          break unless isString
          utils.insertText(input, prefs.root.default.get(pref))
        when keyString == @vimfx.options['options.key.reset_default']
          prefs.root.set(pref, null)
        else
          return

      event.preventDefault()
      setting.valueToPreference()
      @refreshShortcutErrors()
    )
    @listen(@container, 'blur', -> quote = false)

  setupValidation: ->
    @listen(@container, 'input', (event) =>
      setting = event.target
      # Disable default behavior of updating the pref of the setting on each
      # input. Do it on the 'change' event instead (see below), because all
      # settings are validated and auto-adjusted as soon as the pref changes.
      event.stopPropagation()
      if setting.classList.contains('is-shortcut')
        # However, for the shortcuts we _do_ want live validation, because they
        # cannot be auto-adjusted. Instead an error message is shown.
        setting.valueToPreference()
        @refreshShortcutErrors()
    )

    @listen(@container, 'change', (event) ->
      setting = event.target
      unless setting.classList.contains('is-shortcut')
        setting.valueToPreference()
    )

  refreshShortcutErrors: ->
    for setting in @container.getElementsByClassName('is-shortcut')
      setting.setAttribute('desc', @generateErrorMessage(setting.pref))
    return

module.exports = {
  observe
}
