###
# Copyright Anton Khodakivskiy 2013.
# Copyright Simon Lydell 2013, 2014, 2015.
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

legacy        = require('./legacy')
utils         = require('./utils')
_             = require('./l10n')
{ getPref
, setPref
, isPrefSet } = require('./prefs')

class Command
  constructor: (@group, @name, @func, keys) ->
    @prefName = "commands.#{ @name }.keys"
    @keyValues =
      if isPrefSet(@prefName)
        try JSON.parse(getPref(@prefName))
        catch then []
      else
        keys
    for key, index in @keyValues when typeof key == 'string'
      @keyValues[index] = legacy.convertKey(key)

  keys: (value) ->
    if value == undefined
      return @keyValues
    else
      @keyValues = value
      setPref(@prefName, JSON.stringify(value))

  help: -> _("help_command_#{ @name }")

  match: (str, numbers = null) ->
    for key in @keys()
      key = utils.normalizedKey(key)
      if key.startsWith(str)
        # When letter 0 follows after a number, it is considered as number 0
        # instead of a valid command.
        continue if key == '0' and numbers
        count = if numbers then Number(numbers[numbers.length - 1]) else null
        return {match: true, exact: (key == str), command: this, count}

  @searchForMatchingCommand: (commands, keys) ->
    for index in [0...keys.length] by 1
      str = keys[index..].join('')
      numbers = keys[0..index].join('').match(/[1-9]\d*/g)
      for command in commands
        return match if match = command.match(str, numbers)
    return {match: false}

module.exports = Command
