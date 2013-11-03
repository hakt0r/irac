###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

_me = 'env'.blue

require 'coffee-script'

global.EventEmitter = EventEmitter = require('events').EventEmitter
global.colors       = colors       = require 'colors'
global.fs           = fs           = require 'fs'
global.cp           = cp           = require 'child_process'
global.ync          = ync          = require 'ync'
global.optimist     = optimist     = require 'optimist'
global.crypto       = crypto       = require 'crypto'

global.sha512 = sha512 = (str) ->
  h = crypto.createHash 'sha512'
  h.update str
  h.digest 'hex'

global.md5 = md5 = (str) ->
  h = crypto.createHash 'md5'
  h.update str
  h.digest 'hex'

optimist.argv = argv = optimist.parse global.gui.App.argv if global.GUI
global._base = _base = optimist.argv.config || ( process.env.HOME + '/.irac' )

global.Storable = Storable  = require './storable'
global.Settings = Settings  = new Storable _base + '/user.json',
  defaults : name : 'anonymous', port : 33023, torport : 9051
  override : argv

global.OTR = OTR = if global.GUI
    require _base + '/node-webkit/buffertools'
    require _base + '/node-webkit/otr4'
  else
    require 'buffertools'
    require 'otr4'

global.Kreem     = Kreem     = new EventEmitter
global.shell     = shell     = require './ultrashell'
global.Tor       = Tor       = require './tor'
global.Peer      = Peer      = require './peer'
global.Stream    = Stream    = require './stream'
global.Audio     = Audio     = require './audio'
global.Player    = Player    = Audio.Player
global.Recorder  = Recorder  = Audio.Recorder
Kreem[k] = v        for k,v of require './kreem'
