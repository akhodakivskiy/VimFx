###
# Copyright Simon Lydell 2014, 2016.
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

utils = require('../lib/utils')

exports['test selectAllSubstringMatches'] = (assert) ->
  window = utils.getCurrentWindow()
  {document} = window
  selection = window.getSelection()

  # Element creation helper.
  e = (tagName, childNodes = []) ->
    element = document.createElement(tagName)
    element.appendChild(childNode) for childNode in childNodes
    return element

  # Text node creation helper.
  t = (text) -> document.createTextNode(text)

  test = (name, element, string, options, expected) ->
    msg = (message) -> "#{name}: #{message}"

    selection.removeAllRanges()
    utils.selectAllSubstringMatches(element, string, options)

    assert.equal(selection.rangeCount, expected.length, msg('rangeCount'))

    for index in [0...selection.rangeCount] by 1
      range = selection.getRangeAt(index)
      [
        startContainer, startOffset
        endContainer, endOffset
        expectedString = string
      ] = expected[index]
      assert.equal(range.startContainer, startContainer, msg('startContainer'))
      assert.equal(range.startOffset, startOffset, msg('startOffset'))
      assert.equal(range.endContainer, endContainer, msg('endContainer'))
      assert.equal(range.endOffset, endOffset, msg('endOffset'))
      assert.equal(range.toString(), expectedString, msg('toString()'))

    return

  do (name = 'simple case') ->
    element = e('p', [
      (t1 = t('test'))
    ])
    test(name, element, 'es', null, [
      [t1, 1, t1, 3]
    ])

  do (name = 'several matches per text node') ->
    element = e('p', [
      (t1 = t('es test best es'))
    ])
    test(name, element, 'es', null, [
      [t1, 0, t1, 2]
      [t1, 4, t1, 6]
      [t1, 9, t1, 11]
      [t1, 13, t1, 15]
    ])

  do (name = 'split across two text nodes') ->
    element = e('p', [
      (t1 = t('te'))
      (t2 = t('st'))
    ])
    test(name, element, 'es', null, [
      [t1, 1, t2, 1]
    ])

  do (name = 'split across three text nodes') ->
    element = e('p', [
      (t1 = t('te'))
      t('s')
      (t2 = t('t'))
    ])
    test(name, element, 'test', null, [
      [t1, 0, t2, 1]
    ])

  do (name = 'empty text nodes skipped') ->
    element = e('p', [
      t('')
      (t1 = t('a te'))
      t('')
      t('')
      t('s')
      t('')
      (t2 = t('t!'))
      t('')
    ])
    test(name, element, 'test', null, [
      [t1, 2, t2, 1]
    ])

  do (name = 'across several elements') ->
    element = e('p', [
      t('\n  ')
      e('span', [
        (t1 = t('\tte'))
        e('i', [
          t('s')
        ])
      ])
      e('span')
      (t2 = t('t'))
    ])
    test(name, element, 'test', null, [
      [t1, 1, t2, 1]
    ])

  do (name = 'overlapping matches') ->
    element = e('p', [
      (t1 = t('ababaabacaba'))
    ])
    test(name, element, 'aba', null, [
      [t1, 0, t1, 8, 'ababaaba']
      [t1, 9, t1, 12]
    ])

  do (name = 'case sensitivity') ->
    element = e('p', [
      (t1 = t('tESt'))
    ])
    test(name, element, 'TesT', null, [])

  do (name = 'case insensitivity') ->
    element = e('p', [
      (t1 = t('tESt'))
    ])
    test(name, element, 'TesT', {caseSensitive: false}, [
      [t1, 0, t1, 4, 'tESt']
    ])

exports['test bisect'] = (assert) ->
  fn = (num) -> num > 7

  # Non-sensical input.
  assert.deepEqual(utils.bisect(5, 2, fn), [null, null])
  assert.deepEqual(utils.bisect(7.5, 8, fn), [null, null])
  assert.deepEqual(utils.bisect(7, 8.5, fn), [null, null])
  assert.deepEqual(utils.bisect(7.5, 8.5, fn), [null, null])

  # Unfindable bounds.
  assert.deepEqual(utils.bisect(8, 8, fn), [null, 8])
  assert.deepEqual(utils.bisect(7, 7, fn), [7, null])
  assert.deepEqual(utils.bisect(6, 7, fn), [7, null])
  assert.deepEqual(utils.bisect(7, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(1, 2, (n) -> n == 1), [null, null])
  assert.deepEqual(utils.bisect(0, 0, fn), [0, null])

  # Less than.
  assert.deepEqual(utils.bisect(0, 7, fn), [7, null])
  assert.deepEqual(utils.bisect(0, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(1, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(2, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(3, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(4, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(5, 8, fn), [7, 8])
  assert.deepEqual(utils.bisect(6, 8, fn), [7, 8])

  # Greater than.
  assert.deepEqual(utils.bisect(7, 9, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 10, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 11, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 12, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 13, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 14, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 15, fn), [7, 8])
  assert.deepEqual(utils.bisect(7, 16, fn), [7, 8])

  # Various cases.
  assert.deepEqual(utils.bisect(0, 9, fn), [7, 8])
  assert.deepEqual(utils.bisect(5, 9, fn), [7, 8])
  assert.deepEqual(utils.bisect(6, 10, fn), [7, 8])
  assert.deepEqual(utils.bisect(0, 12345, fn), [7, 8])

exports['test removeDuplicates'] = (assert) ->
  assert.deepEqual(utils.removeDuplicates(
    [1, 1, 2, 1, 3, 2]),
    [1, 2, 3]
  )
  assert.deepEqual(utils.removeDuplicates(
    ['a', 'b', 'c', 'b', 'd', 'a']),
    ['a', 'b', 'c', 'd']
  )
