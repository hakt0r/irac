require 'coffee-script'

class Storable
  constructor : (@path, @defaults) ->
  read : (callback) =>
    _read = (inp) =>
      inp = {} unless inp?
      inp[k] = v for k,v of @defaults when not inp[k]?
      @[k] = v for k,v of inp
      callback inp if callback?
    fs.readFile @path, (err, data) =>
      try _read JSON.parse data.toString('utf8')
      catch e
        console.error e
        _read {}
    null
  save : (callback) =>
    out = {}
    out[k] = v for k,v of @ when typeof v isnt 'function' and k isnt 'path' and k isnt 'defaults'
    fs.writeFile @path, JSON.stringify(out), callback
    null

global._base    = _base    = process.env.HOME + '/.irac'
global.Settings = Settings = new Storable _base + '/user.json', name : 'anonymous'
global.Storable = Storable
global.colors   = colors   = require 'colors'
global.optimist = optimist = require 'optimist'
global.fs       = fs       = require 'fs'
global.ync      = ync      = require 'ync'
global.shell    = shell    = require './ultrashell'
global.Tor      = Tor      = require('./tor')
global.Kreem    = Kreem    = require('./kreem')
global.sha512   = sha512   = require './sha512'
global.Player   = Player   = Kreem.Player
global.Recorder = Recorder = Kreem.Recorder
global.Stream   = Stream   = Kreem.Stream
global.Peer     = Peer     = Kreem.Peer

require if global.GUI then _base + '/node-webkit/buffertools/buffertools' else 'buffertools'

config_dir = (callback) -> fs.exists _base, (exists) ->
  if exists then callback()
  else fs.mkdir _base, (result) ->
    console.log _me, 'created', _base, if result? then result else ''
    callback() if callback?

Kreem.init = (callback) -> new ync.Sync
  config_dir    : -> config_dir    @proceed
  read_settings : -> Settings.read @proceed
  #log_settings : ->
  #  console.log "CO_base:", _base
  #  console.log Settings; @proceed()
  ready : callback

Settings.nick = optimist.argv.nick if optimist.argv.nick?