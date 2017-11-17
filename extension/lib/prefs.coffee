# This file provides an API a bit more easy to use than the very low-level
# Firefox prefs APIs.

defaults = require('./defaults')

{prefs} = Services

branches = {
  addon: {
    user: prefs.getBranch(defaults.BRANCH)
    default: prefs.getDefaultBranch(defaults.BRANCH)
  }
  root: {
    user: prefs
    default: prefs.getDefaultBranch('')
  }
}

get = (branch, key) ->
  return switch branch.getPrefType(key)
    when branch.PREF_BOOL
      branch.getBoolPref(key)
    when branch.PREF_INT
      branch.getIntPref(key)
    when branch.PREF_STRING
      branch.getCharPref(key)

set = (branch, key, value) ->
  switch typeof value
    when 'boolean'
      branch.setBoolPref(key, value)
    when 'number'
      branch.setIntPref(key, value) # `value` will be `Math.floor`ed.
    when 'string'
      branch.setCharPref(key, value)
    else
      if value == null
        branch.clearUserPref(key)
      else
        throw new Error(
          "VimFx: Options may only be set to a boolean, number, string or null.
          Got: #{typeof value}"
        )

has = (branch, key) ->
  branch.prefHasUserValue(key)

tmp = (branch, pref, temporaryValue) ->
  previousValue = if has(branch, pref) then get(branch, pref) else null
  set(branch, pref, temporaryValue)
  return -> set(branch, pref, previousValue)

observe = (branch, domain, callback) ->
  observer = {observe: (branch, topic, changedPref) -> callback(changedPref)}
  branch.addObserver(domain, observer, false)
  module.onShutdown(->
    branch.removeObserver(domain, observer)
  )

module.exports = {
  get: get.bind(null, branches.addon.user)
  set: set.bind(null, branches.addon.user)
  has: has.bind(null, branches.addon.user)
  tmp: tmp.bind(null, branches.addon.user)
  observe: observe.bind(null, branches.addon.user)
  default: {
    get: get.bind(null, branches.addon.default)
    set: set.bind(null, branches.addon.default)
    init: ->
      for key, value of defaults.all_prefs
        module.exports.default.set(key, value)
      return
  }
  root: {
    get: get.bind(null, branches.root.user)
    set: set.bind(null, branches.root.user)
    has: has.bind(null, branches.root.user)
    tmp: tmp.bind(null, branches.root.user)
    observe: observe.bind(null, branches.root.user)
    default: {
      get: get.bind(null, branches.root.default)
      set: set.bind(null, branches.root.default)
    }
  }
  unbound: {get, set, has, tmp, observe}
}
