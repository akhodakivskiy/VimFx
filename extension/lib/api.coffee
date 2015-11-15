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

# This file defines VimFx’s public API.

defaults = require('./defaults')
prefs    = require('./prefs')
utils    = require('./utils')

counter = new utils.Counter({start: 10000, step: 100})

createAPI = (vimfx) ->
  get: (pref) -> switch
    when pref of defaults.parsed_options
      defaults.parsed_options[pref]
    when pref of defaults.all_prefs or pref?.startsWith('custom.')
      prefs.get(pref)
    else
      throw new Error("VimFx: Unknown pref: #{pref}")

  getDefault: (pref) -> switch
    when pref of defaults.parsed_options or pref?.startsWith('custom.')
      throw new Error("VimFx: No default for pref: #{pref}")
    when pref of defaults.all_prefs
      defaults.all_prefs[pref]
    else
      throw new Error("VimFx: Unknown pref: #{pref}")

  set: (pref, value) -> switch
    when pref of defaults.parsed_options
      vimfx.options[pref] = value
    when pref of defaults.all_prefs or pref?.startsWith('custom.')
      prefs.set(pref, value)
    else
      throw new Error("VimFx: Unknown pref: #{pref}")

  addCommand: ({name, description, mode, category, order} = {}, fn) ->
    mode     ?= 'normal'
    category ?= if mode == 'normal' then 'misc' else ''
    order    ?= counter.tick()

    unless typeof name == 'string'
      throw new Error("VimFx: A command name as a string is required.
                       Got: #{name}")
    unless /^[a-z_]+$/.test(name)
      throw new Error("VimFx: Command names should only consist of a-z
                       (lowercase) and underscores. Got: #{name}")
    unless typeof description == 'string' and description != ''
      throw new Error("VimFx: Commands must have a non-empty description.
                       Got: #{description}")
    unless utils.has(vimfx.modes, mode)
      modes = Object.keys(vimfx.modes).join(', ')
      throw new Error("VimFx: Unknown mode. Available modes are: #{modes}.
                       Got: #{mode}")
    unless utils.has(vimfx.options.categories, category)
      categories = Object.keys(vimfx.options.categories).join(', ')
      throw new Error("VimFx: Unknown category. Available categories are:
                       #{categories}. Got: #{category}")
    unless typeof order == 'number'
      throw new Error("VimFx: Command order must be a number. Got: #{order}")
    unless typeof fn == 'function'
      throw new Error("VimFx: Commands need a function to run. Got: #{fn}")

    pref = "#{defaults.BRANCH}custom.mode.#{mode}.#{name}"
    prefs.root.default.set(pref, '')
    vimfx.modes[mode].commands[name] = {
      pref, category, order, run: fn, description: -> description
    }

  addOptionOverrides: (rules...) ->
    unless vimfx.optionOverrides
      vimfx.optionOverrides = []
      vimfx.options = new Proxy(vimfx.options, {
        get: (options, pref) ->
          location = utils.getCurrentLocation()
          overrides = getOverrides(vimfx.optionOverrides, location)
          return overrides?[pref] ? options[pref]
      })
    vimfx.optionOverrides.push(rules...)

  addKeyOverrides: (rules...) ->
    unless vimfx.keyOverrides
      vimfx.keyOverrides = []
      vimfx.options.keyValidator = (keyStr, mode) ->
        location = utils.getCurrentLocation()
        overrides = getOverrides(vimfx.keyOverrides, location, mode)
        return keyStr not in (overrides ? [])
    vimfx.keyOverrides.push(rules...)

  on:      vimfx.on.bind(vimfx)
  modes:   vimfx.modes

getOverrides = (rules, args...) ->
  for [match, overrides] in rules
    return overrides if match(args...)
  return null

module.exports = createAPI
