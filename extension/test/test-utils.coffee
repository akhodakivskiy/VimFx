###
# Copyright Simon Lydell 2014.
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
