###
# Copyright Simon Lydell 2015, 2016.
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

# This file defines VimFx’s config file API.

defaults = require('./defaults')
prefs = require('./prefs')
utils = require('./utils')
Vim = require('./vim')

counter = new utils.Counter({start: 10000, step: 100})

createConfigAPI = (vimfx, {allowDeprecated = true} = {}) -> {
  get: (inputPref) ->
    pref = alias(inputPref, allowDeprecated)
    if pref != inputPref
      try return prefs.get(inputPref)
    return switch
      when pref of defaults.parsed_options
        vimfx.options[pref]
      when pref of defaults.all_prefs or pref?.startsWith('custom.')
        prefs.get(pref)
      else
        throw new Error("VimFx: Unknown option: #{pref}")

  getDefault: (inputPref) ->
    pref = alias(inputPref, allowDeprecated)
    if pref != inputPref
      try return prefs.default.get(inputPref)
    return switch
      when pref of defaults.parsed_options or pref?.startsWith('custom.')
        throw new Error("VimFx: No default for option: #{pref}")
      when pref of defaults.all_prefs
        defaults.all_prefs[pref]
      else
        throw new Error("VimFx: Unknown option: #{pref}")

  set: (inputPref, value) ->
    pref = alias(inputPref, allowDeprecated)
    switch
      when pref of defaults.parsed_options
        previousValue = vimfx.options[pref]
        vimfx.options[pref] = value
        onShutdown(vimfx, -> vimfx.options[pref] = previousValue)
      when pref of defaults.all_prefs or pref?.startsWith('custom.')
        previousValue = if prefs.has(pref) then prefs.get(pref) else null
        prefs.set(pref, value)
        onShutdown(vimfx, -> prefs.set(pref, previousValue))
      else
        throw new Error("VimFx: Unknown option: #{pref}")

  addCommand: ({name, description, mode, category, order} = {}, fn) ->
    mode ?= 'normal'
    category ?= if mode == 'normal' then 'misc' else ''
    order ?= counter.tick()

    unless typeof name == 'string'
      throw new Error(
        "VimFx: A command name as a string is required. Got: #{name}"
      )
    unless /^[a-z_]+$/.test(name)
      throw new Error(
        "VimFx: Command names should only consist of a-z (lowercase) and
         underscores. Got: #{name}"
      )
    unless typeof description == 'string' and description != ''
      throw new Error(
        "VimFx: Commands must have a non-empty description. Got: #{description}"
      )
    unless utils.has(vimfx.modes, mode)
      modes = Object.keys(vimfx.modes).join(', ')
      throw new Error(
        "VimFx: Unknown mode. Available modes are: #{modes}. Got: #{mode}"
      )
    unless utils.has(vimfx.options.categories, category)
      categories = Object.keys(vimfx.options.categories).join(', ')
      throw new Error(
        "VimFx: Unknown category. Available categories are: #{categories}.
         Got: #{category}"
      )
    unless typeof order == 'number'
      throw new Error("VimFx: Command order must be a number. Got: #{order}")
    unless typeof fn == 'function'
      throw new Error("VimFx: Commands need a function to run. Got: #{fn}")

    pref = "#{defaults.BRANCH}custom.mode.#{mode}.#{name}"
    prefs.root.default.set(pref, '')
    vimfx.modes[mode].commands[name] = {
      pref, category, order, run: fn, description
    }
    onShutdown(vimfx, -> delete vimfx.modes[mode].commands[name])

  addOptionOverrides: (rules...) ->
    validateRules(rules, (override) ->
      unless Object::toString.call(override) == '[object Object]'
        return 'an object'
      return null
    )

    unless vimfx.optionOverrides
      vimfx.optionOverrides = []
      vimfx.options = new Proxy(vimfx.options, {
        get: (options, pref) ->
          location = utils.getCurrentLocation()
          return options[pref] unless location
          overrides = getOverrides(vimfx.optionOverrides ? [], location)
          return overrides?[pref] ? options[pref]
      })
      onShutdown(vimfx, -> vimfx.optionOverrides = null)

    vimfx.optionOverrides.push(rules...)

  addKeyOverrides: (rules...) ->
    validateRules(rules, (override) ->
      unless Array.isArray(override) and
             override.every((item) -> typeof item == 'string')
        return 'an array of strings'
      return null
    )

    unless vimfx.keyOverrides
      vimfx.keyOverrides = []
      vimfx.options.keyValidator = (keyStr, mode) ->
        return true unless mode == 'normal'
        location = utils.getCurrentLocation()
        return true unless location
        overrides = getOverrides(vimfx.keyOverrides ? [], location)
        return keyStr not in (overrides ? [])
      onShutdown(vimfx, -> vimfx.keyOverrides = null)

    vimfx.keyOverrides.push(rules...)

  send: (vim, message, data = null, callback = null) ->
    unless vim instanceof Vim
      throw new Error(
        "VimFx: The first argument must be a vim object. Got: #{vim}"
      )
    unless typeof message == 'string'
      throw new Error(
        "VimFx: The second argument must be a message string. Got: #{message}"
      )
    if typeof data == 'function'
      throw new Error(
        "VimFx: The third argument must not be a function. Got: #{data}"
      )

    unless typeof callback == 'function' or callback == null
      throw Error(
        "VimFx: If provided, `callback` must be a function. Got: #{callback}"
      )
    vim._send(message, data, callback, {prefix: 'config:'})

  on: (event, listener) ->
    validateEventListener(event, listener)
    vimfx.on(event, listener)
    onShutdown(vimfx, -> vimfx.off(event, listener))

  off: (event, listener) ->
    validateEventListener(event, listener)
    vimfx.off(event, listener)

  modes: vimfx.modes
}

# Don’t crash the users’s entire config file on startup if they happen to try to
# set a renamed pref (only warn), but do throw an error if they reload the
# config file; then they could update while editing the file anyway.
alias = (pref, allowDeprecated) ->
  if pref of renamedPrefs
    newPref = renamedPrefs[pref]
    message = "VimFx: `#{pref}` has been renamed to `#{newPref}`."
    if allowDeprecated
      console.warn(message)
      return newPref
    else
      throw new Error(message)
  else
    return pref

renamedPrefs = {
  'hint_chars': 'hints.chars'
  'hints_sleep': 'hints.sleep'
  'hints_timeout': 'hints.matched_timeout'
  'hints_peek_through': 'hints.peek_through'
  'hints_toggle_in_tab': 'hints.toggle_in_tab'
  'hints_toggle_in_background': 'hints.toggle_in_background'
  'mode.hints.delete_hint_char': 'mode.hints.delete_char'
}

getOverrides = (rules, args...) ->
  for [matcher, override] in rules
    return override if matcher(args...)
  return null

validateRules = (rules, overrideValidator) ->
  for rule in rules
    unless Array.isArray(rule)
      throw new Error(
        "VimFx: An override rule must be an array. Got: #{rule}"
      )
    unless rule.length == 2
      throw new Error(
        "VimFx: An override rule array must be of length 2. Got: #{rule.length}"
      )
    [matcher, override] = rule
    unless typeof matcher == 'function'
      throw new Error(
        "VimFx: The first item of an override rule array must be a function.
         Got: #{matcher}"
      )
    overrideValidationMessage = overrideValidator(override)
    if overrideValidationMessage
      throw new Error(
        "VimFx: The second item of an override rule array must be
         #{overrideValidationMessage}. Got: #{override}"
      )
  return

validateEventListener = (event, listener) ->
  unless typeof event == 'string'
    throw new Error(
      "VimFx: The first argument must be a string. Got: #{event}"
    )
  unless typeof listener == 'function'
    throw new Error(
      "VimFx: The second argument must be a function. Got: #{listener}"
    )
  return

onShutdown = (vimfx, handler) ->
  fn = ->
    handler()
    vimfx.off('shutdown', fn)
  vimfx.on('shutdown', fn)

module.exports = createConfigAPI
