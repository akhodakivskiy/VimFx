###
# Copyright Simon Lydell 2016.
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

# This file provides a basic assertion library.

createError = (description, message = '') ->
  formattedMessage = if message then "\nMessage: #{message}" else ''
  error = new Error("Expected #{description}.#{formattedMessage}")
  error.stack = error.stack.split('\n')[1..]
  return error

format = (value) ->
  try
    string = JSON.stringify(value)
    if string? and not
       (string == '{}' and Object::toString.call(value) != '[object Object]')
      return string
  return String(value)

arrayEqual = (actual, expected, message = '') ->
  unless Array.isArray(actual) and Array.isArray(expected)
    throw createError(
      "two arrays to compare. Got: #{format(actual)} and #{format(expected)}",
      message
    )
  unless actual.length == expected.length and
         actual.every((actualItem, index) -> actualItem == expected[index])
    throw createError(
      "#{format(actual)} to array-equal #{format(expected)}",
      message
    )

equal = (actual, expected, message = '') ->
  return if actual == expected
  throw createError("#{format(actual)} to equal #{format(expected)}", message)

notEqual = (actual, expected, message = '') ->
  return if actual != expected
  throw createError(
    "#{format(actual)} NOT to equal #{format(expected)}",
    message
  )

ok = (actual, message = '') ->
  return if actual
  throw createError("#{format(actual)} to be truthy", message)

throws = (regex, badValue, fn) ->
  try fn() catch error
    start = 'VimFx:'
    unless error.message.startsWith(start)
      throw createError(
        "thrown error message #{format(error.message)} to start with
         #{format(start)}")
    end = ": #{badValue}"
    unless error.message.endsWith(end)
      throw createError(
        "thrown error message #{format(error.message)} to end with
         #{format(end)}")
    unless regex.test(error.message)
      throw createError(
        "thrown error message #{format(error.message)} to match the regex
         #{format(regex)}")
    return
  throw createError("function to throw, but it did not: #{format(fn)}")

module.exports = {
  arrayEqual
  equal
  notEqual
  ok
  throws
}
