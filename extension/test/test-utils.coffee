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

exports['test removeDuplicates'] = (assert) ->
  assert.deepEqual(utils.removeDuplicates([1, 1, 2, 1, 3, 2]),
                                          [1, 2, 3])
  assert.deepEqual(utils.removeDuplicates(['a', 'b', 'c', 'b', 'd', 'a']),
                                          ['a', 'b', 'c', 'd'])
