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

fs         = require('fs')
{ join }   = require('path')
request    = require('request')
gulp       = require('gulp')
changed    = require('gulp-changed')
coffee     = require('gulp-coffee')
coffeelint = require('gulp-coffeelint')
git        = require('gulp-git')
header     = require('gulp-header')
merge      = require('gulp-merge')
mustache   = require('gulp-mustache')
util       = require('gulp-util')
zip        = require('gulp-zip')
rimraf     = require('rimraf')

DEST   = 'build'
XPI    = 'VimFx.xpi'
LOCALE = 'extension/locale'

read = (filepath) -> fs.readFileSync(filepath).toString()
template = (data) -> mustache(data, {extension: ''})

gulp.task('default', ['push'])

gulp.task('clean', (callback) ->
  rimraf(DEST, callback)
)

gulp.task('copy', ->
  gulp.src(['extension/**/!(*.coffee|*.tmpl)', 'COPYING'])
    .pipe(changed(DEST))
    .pipe(gulp.dest(DEST))
)

gulp.task('coffee', ->
  gulp.src('extension/**/*.coffee')
    .pipe(changed(DEST, {extension: '.coffee'}))
    .pipe(coffee({bare: true}).on('error', util.log))
    .pipe(gulp.dest(DEST))
)

gulp.task('chrome.manifest', ->
  gulp.src('extension/chrome.manifest.tmpl')
    .pipe(template({locales: fs.readdirSync(LOCALE).map((locale) -> {locale})}))
    .pipe(gulp.dest(DEST))
)

gulp.task('install.rdf', ->
  pkg = require('./package.json')

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

gulp.task('build', ['copy', 'coffee', 'chrome.manifest', 'install.rdf'])

gulp.task('xpi', ['build'], ->
  gulp.src("#{ DEST }/**/!(#{ XPI })")
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
  { version } = require('./package.json')
  message = "VimFx v#{ version }"
  today = new Date().toISOString()[...10]
  merge(
    gulp.src('package.json'),
    gulp.src('CHANGELOG.md')
      .pipe(header("### #{ version } (#{ today })\n"))
      .pipe(gulp.dest('.'))
  ).pipe(git.commit(message))
  git.tag(version, message)
)
