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

fs          = require('fs')
{ join }    = require('path')
gulp        = require('gulp')
coffee      = require('gulp-coffee')
coffeelint  = require('gulp-coffeelint')
git         = require('gulp-git')
header      = require('gulp-header')
merge       = require('gulp-merge')
mustache    = require('gulp-mustache')
zip         = require('gulp-zip')
precompute  = require('require-precompute')
request     = require('request')
rimraf      = require('rimraf')
runSequence = require('run-sequence')
pkg         = require('./package.json')

DEST   = 'build'
XPI    = 'VimFx.xpi'
LOCALE = 'extension/locale'
TEST   = 'extension/test'

test = '--test' in process.argv or '-t' in process.argv
ifTest = (value) -> if test then [value] else []

read = (filepath) -> fs.readFileSync(filepath).toString()
template = (data) -> mustache(data, {extension: ''})

gulp.task('default', ['push'])

gulp.task('clean', (callback) ->
  rimraf(DEST, callback)
)

gulp.task('copy', ->
  gulp.src(['extension/**/!(*.coffee|*.tmpl)', 'COPYING'])
    .pipe(gulp.dest(DEST))
)

gulp.task('node_modules', ->
  dependencies = (name for name of pkg.dependencies)
  # Note! When installing or updating node modules, make sure that the following
  # glob does not include too much or too little!
  gulp.src("node_modules/+(#{ dependencies.join('|') })/**/{*.js,LICENSE}")
    .pipe(gulp.dest("#{ DEST }/node_modules"))
)

gulp.task('coffee', ->
  gulp.src([
    'extension/bootstrap.coffee'
    'extension/lib/**/*.coffee'
    ifTest('extension/test/**/*.coffee')...
  ], {base: 'extension'})
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest(DEST))
)

gulp.task('chrome.manifest', ->
  gulp.src('extension/chrome.manifest.tmpl')
    .pipe(template({locales: fs.readdirSync(LOCALE).map((locale) -> {locale})}))
    .pipe(gulp.dest(DEST))
)

gulp.task('install.rdf', ->
  [ [ { name: creator } ], developers, contributors, translators ] =
    read('PEOPLE.md').trim().replace(/^#.+\n|^\s*-\s*/mg, '').split('\n\n')
    .map((block) -> block.split('\n').map((name) -> {name}))

  getDescription = (locale) -> read(join(LOCALE, locale, 'description')).trim()

  descriptions = fs.readdirSync(LOCALE)
    .map((locale) -> {
      locale: locale
      description: getDescription(locale)
    })

  gulp.src('extension/install.rdf.tmpl')
    .pipe(template({
      version: pkg.version
      minVersion: pkg.firefoxVersions.min
      maxVersion: pkg.firefoxVersions.max
      creator, developers, contributors, translators
      defaultDescription: getDescription('en-US')
      descriptions
    }))
    .pipe(gulp.dest(DEST))
)

gulp.task('require-data', ['node_modules'], ->
  data = JSON.stringify(precompute('.'), null, 2)
  gulp.src('extension/require-data.js.tmpl')
    .pipe(template({data}))
    .pipe(gulp.dest(DEST))
)

gulp.task('tests-list', ->
  list = JSON.stringify(fs.readdirSync(TEST)
    .map((name) -> name.match(/^(test-.+)\.coffee$/)?[1])
    .filter(Boolean)
  )
  gulp.src("#{ TEST }/tests-list.js.tmpl", {base: 'extension'})
    .pipe(template({list}))
    .pipe(gulp.dest(DEST))
)

gulp.task('templates', [
  'chrome.manifest'
  'install.rdf'
  'require-data'
  ifTest('tests-list')...
])

gulp.task('build', (callback) ->
  runSequence(
    'clean',
    ['copy', 'node_modules', 'coffee', 'templates'],
    callback
  )
)

gulp.task('xpi', ['build'], ->
  gulp.src("#{ DEST }/**/*")
    .pipe(zip(XPI, {compress: false}))
    .pipe(gulp.dest(DEST))
)

gulp.task('push', ['xpi'], ->
  body = fs.readFileSync(join(DEST, XPI))
  request.post({url: 'http://localhost:8888', body })
)

gulp.task('lint', ->
  gulp.src(['extension/**/*.coffee', 'gulpfile.coffee'])
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
)

gulp.task('release', ->
  { version } = pkg
  message = "VimFx v#{ version }"
  today = new Date().toISOString()[...10]
  merge(
    gulp.src('package.json'),
    gulp.src('CHANGELOG.md')
      .pipe(header("### #{ version } (#{ today })\n\n"))
      .pipe(gulp.dest('.'))
  ).pipe(git.commit(message))
  git.tag("v#{ version }", message, (error) -> throw error if error)
)
