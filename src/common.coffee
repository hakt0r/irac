###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

module.exports = (opts={}) ->
  require 'coffee-script'

  # Create the api Object
  EventEmitter = require('events').EventEmitter

  class IRApi extends EventEmitter
    installList : {}
    install : (mod, callback) ->
      npm = require 'npm'
      npm.load null, =>
        npm.commands.install Object.keys(@installList), callback
        npm.on 'log', console.log
        npm.on 'debug', console.log
    require : (mod) ->
      if mod.match(/^git:\/\//) isnt null or mod.match(/^https:\/\//) isnt null
        modsrc = mod
      else if m = require mod then try
        require.resolve mod
      if modsrc? then @installList[modsrc] = true
      else @installList[mod] = true

  global.api = api = new IRApi
  api.EventEmitter = EventEmitter
  api[k] = v for k,v of opts

  api.optimist = optimist = require 'optimist'
  api.ync = require 'ync'
  api.xl = require 'xumlib'

  # Check out the environment
  api.os  = os = require 'os'
  os.arch = os.arch().toLowerCase() # TOTHINK: overcache, consider maybe not
  os.type = os.type().toLowerCase() # TOTHINK: overcache, consider maybe not

  # Library exports, node-webkit is the reason for using the global.api scope
  api.fs = fs = require 'fs'
  api.path    = require 'path'
  api.colors  = require 'colors'
  api.cp      = require 'child_process'

  # Quick crypto functions {everyday hashes}
  api.crypto = crypto = require 'crypto'

  api.sha512 = (str) ->
    h = crypto.createHash 'sha512'
    h.update str
    h.digest 'hex'

  api.md5 = (str) ->
    h = crypto.createHash 'md5'
    h.update str
    h.digest 'hex'

  api.mkdir = (dir,callback=null) ->
    fs.exists dir, (exists) -> if exists then callback false else fs.mkdir dir, callback

  # Setup DOTDIR path
  DOTDIR = null; _dotdir = ->
    api.DOTDIR = DOTDIR = optimist.argv.config || ( process.env.HOME + '/.irac' )

  # Handle node-webit vs. nodejs [modules] and [argv] respectively
  api.OTR = OTR = if api.GUI
      optimist.argv = argv = optimist.parse api.gui.App.argv
      _dotdir()
      require DOTDIR + '/nwmod/buffertools' # load buffertools
      require DOTDIR + '/nwmod/otr4' # return otr object
    else
      _dotdir()
      require 'buffertools' # load buffertools
      require 'otr4'  # return otr object

  # Initialize Settings object
  api.Storable = require 'storable'
  api.Settings = Settings = new api.Storable DOTDIR + '/user.json',
    defaults : name : 'anonymous', port : 33023, torport : 9060, reconnect_interval : 5000
    override : argv
  Settings.buddy = {} unless Settings.buddy?

  # Load core modules
  for m in [ 'i19', 'tor', 'audio', 'kreem', 'tools' ]
    api[k] = v for k,v of require './' + m
