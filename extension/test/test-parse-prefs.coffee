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

prefs = require('../lib/prefs')

resetPrefOnTeardown = (pref, teardown) ->
  previousValue = if prefs.has(pref) then prefs.get(pref) else null
  teardown(->
    prefs.set(pref, previousValue)
  )

testPref = (pref, fn) ->
  return (assert, $vimfx, teardown) ->
    resetPrefOnTeardown(pref, teardown)
    test = (input, output) ->
      prefs.set(pref, input)
      actual = prefs.get(pref)
      if typeof output == 'string'
        assert.equal(actual, output)
      else
        assert.ok(
          output.test(actual),
          "#{output}.test(#{JSON.stringify(actual)})"
        )
    fn(test)

testPrefParsed = (pref, fn) ->
  return (assert, $vimfx, teardown) ->
    resetPrefOnTeardown(pref, teardown)
    test = (input, fn2) ->
      prefs.set(pref, input)
      fn2($vimfx.options[pref])
    fn(assert, test)

exports['test hints.chars'] = testPref('hints.chars', (test) ->
  # Invalid values.
  test('', /^([a-z]) (?!\1)[a-z]$/)
  test(' ', /^([a-z]) (?!\1)[a-z]$/)
  test('a', /^a [b-z]$/)
  test('aa', /^a [b-z]$/)

  # Whitespace handling.
  test('ab', 'a b')
  test('  a  b\t', 'a b')
  test('a\tb', 'a b')

  # Automatic grouping.
  test('abc', 'ab c')
  test('abcd', 'ab cd')
  test('abcde', 'abc de')
  test('abcdef', 'abcd ef')

  # Use last space.
  test('ab  cde f  ', 'abcde f')
  test('ab  cde\tf  ', 'abcde f')

  # Remove duplicates.
  test('aba  fcAde\tf!.!e  ', 'abfcAde !.')
)

spaceDelimitedStringPrefs = [
  'prev_patterns', 'next_patterns', 'blacklist', 'prevent_autofocus_modes'
  'adjustable_element_keys', 'activatable_element_keys', 'pattern_attrs'
]
spaceDelimitedStringPrefs.forEach((pref) ->
  exports["test #{pref}"] = testPref(pref, (test) ->
    # Empty values.
    test('', '')
    test(' ', '')
    test('\t  ', '')

    # Simple cases.
    test('a', 'a')
    test(' a', 'a')
    test('a ', 'a')
    test('a\t', 'a')
    test('  abc  def\tg', 'abc  def  g')

    # Remove duplicates.
    test('a a ab A aB AB ABC AB', 'a  ab  A  aB  AB  ABC')
  )
)

['prev_patterns', 'next_patterns'].forEach((pref) ->
  exports["test #{pref} regex"] = testPrefParsed(pref, (assert, test) ->
    test('previous  previous\\S*  foo(', (parsed) ->
      # Case insensitivity.
      assert.ok(parsed[0].test('previous'))
      assert.ok(parsed[0].test('PREVIOUS'))
      assert.ok(parsed[0].test('Previous'))

      # Whitespace handling.
      assert.ok(parsed[0].test(' previous'))
      assert.ok(parsed[0].test('previous '))
      assert.ok(parsed[0].test(' previous '))

      # Must match at start or end.
      assert.ok(parsed[0].test('previous b'))
      assert.ok(parsed[0].test('a previous'))
      assert.ok(not parsed[0].test('a previous b'))

      # Must match entire words.
      assert.ok(not parsed[0].test('previously'))
      assert.ok(not parsed[0].test('previouså'))

      # Regex.
      assert.ok(parsed[1].test('previous'))
      assert.ok(parsed[1].test('previously'))
      assert.ok(not parsed[1].test('foopreviously'))
      assert.ok(not parsed[1].test('a previously b'))

      # Regex escape.
      assert.ok(parsed[2].test('foo('))
    )
  )
)

exports['test blacklist regex'] = testPrefParsed('blacklist', (assert, test) ->
  test('example  *EXAMPLE*  *example.com/?*=}*', (parsed) ->
    # Case insensitivity.
    assert.ok(parsed[0].test('example'))
    assert.ok(parsed[0].test('EXAMPLE'))
    assert.ok(parsed[0].test('Example'))

    # Must match entire string.
    assert.ok(not parsed[0].test('http://example.com'))

    # Wildcard.
    assert.ok(parsed[1].test('http://example.com'))
    assert.ok(parsed[1].test('http://foobar/?q=examples'))

    # Regex escape.
    assert.ok(parsed[2].test('https://www.example.com/?test=}&foo=bar'))
  )
)
