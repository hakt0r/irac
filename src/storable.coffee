fs = require 'fs'

module.exports = class Storable
  constructor : (@path, opts={}) ->
    { @defaults, @override } = opts
    null
  read : (callback) =>
    _read = (inp) =>
      inp = {} unless inp?
      if @defaults?
        inp[k] = v for k,v of @defaults when not inp[k]?
        inp[k] = v for k,v of @defaults when typeof v is 'Number' and typeof inp[k] isnt 'Number'
      inp[k] = v for k,v of @override if @override?
      console.debug inp, @override, @defaults
      @override = null
      @[k] = v for k,v of inp
      callback inp if callback?
    fs.readFile @path, (err, data) =>
      try _read JSON.parse data.toString('utf8')
      catch e
        console.warn 'wrn'.yellow, 'using defaults', e
        _read {}
        @save()
    null
  override : (opts={}) =>
    change = no
    for k, v of opts
      change = yes
      @[k] = v
    try Settings.save() if change
    null
  save : (callback) =>
    out = {}
    out[k] = v for k,v of @ when typeof v isnt 'function' and k isnt 'path' and k isnt 'defaults'
    fs.writeFile @path, JSON.stringify(out), callback
    null