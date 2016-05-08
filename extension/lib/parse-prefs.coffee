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

# This file parses string prefs into more easily used data structures.

defaults = require('./defaults')
prefs = require('./prefs')
utils = require('./utils')

MIN_NUM_HINT_CHARS = 2

parsePref = (pref) ->
  # Parsed options are not stored in Firefox’s prefs system, and are therefore
  # always read from the defaults. The only way to override them is via the
  # config file API.
  if pref of defaults.parsed_options
    return defaults.parsed_options[pref]

  value = prefs.get(pref)

  if pref of parsers
    {parsed, normalized} = parsers[pref](value, defaults.all_options[pref])
    if normalized? and normalized != value and prefs.has(pref)
      prefs.set(pref, normalized)
    return parsed

  return value

# Splits a whitespace delimited string into an array, with empty elements and
# duplicates filtered.
parseSpaceDelimitedString = (value) ->
  parsed = utils.removeDuplicates(value.split(/\s+/)).filter(Boolean)
  return {parsed, normalized: parsed.join('  ')}

parsePatterns = (value) ->
  result = parseSpaceDelimitedString(value)
  # The patterns are case insensitive regexes and must match either in the
  # beginning or at the end of a string. They do not match in the middle of
  # words, so "previous" does not match "previously" (`previous\S*` can be used
  # for that case). Note: `\s` is used instead of `\b` since it works better
  # with non-English characters.
  result.parsed = result.parsed.map((pattern) ->
    patternRegex =
      try
        RegExp(pattern).source
      catch
        utils.regexEscape(pattern)
    return ///
      ^\s*     (?:#{patternRegex}) (?:\s|$)
      |
      (?:\s|^) (?:#{patternRegex}) \s*$
    ///i
  )
  return result

parsers = {
  hint_chars: (value, defaultValue) ->
    [leading..., end] = value.trim().split(/\s+/)
    parsed = if leading.length > 0 then "#{leading.join('')} #{end}" else end
    parsed = utils.removeDuplicateCharacters(parsed)

    # Make sure that hint chars contain at least the required amount of chars.
    if parsed.length < MIN_NUM_HINT_CHARS
      parsed = defaultValue[...MIN_NUM_HINT_CHARS]

    unless parsed.includes(' ')
      numDefaultSecondaryHintChars =
        defaultValue.length - 1 - defaultValue.indexOf(' ')
      index = Math.min(parsed.length // 2, numDefaultSecondaryHintChars)
      parsed = "#{parsed[...-index]} #{parsed[-index..]}"

    return {parsed, normalized: parsed}

  prev_patterns: parsePatterns
  next_patterns: parsePatterns

  blacklist: (value) ->
    result = parseSpaceDelimitedString(value)
    result.parsed = result.parsed.map((pattern) ->
      return ///^#{utils.regexEscape(pattern).replace(/\\\*/g, '.*')}$///i
    )
    return result

  prevent_autofocus_modes: parseSpaceDelimitedString

  adjustable_element_keys: parseSpaceDelimitedString
  activatable_element_keys: parseSpaceDelimitedString

  pattern_attrs: parseSpaceDelimitedString
}

module.exports = parsePref
