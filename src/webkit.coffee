# Load native UI library
gui = require 'nw.gui'

tray = new gui.Tray
  title : 'irac'
  icon  : 'img/logo.png'

menu = new gui.Menu();
menu.append new gui.MenuItem type:  'checkbox', label: 'Online'
menu.append new gui.MenuItem type:  'checkbox', label: 'Talk', click : -> Recorder.toggle()
menu.append new gui.MenuItem label: 'Settings'
menu.append new gui.MenuItem type:  'separator'
menu.append new gui.MenuItem label: 'Quit', click : -> process.exit(0)
tray.menu = menu

require 'buffertools'
require 'coffee-script'

global.colors       = colors   = require 'colors'
global.optimist     = optimist = require 'optimist'
global.fs           = fs       = require 'fs'
global.ync          = ync      = require 'ync'
global.shell        = shell    = require './node_modules/cerosine/lib/ultrashell'
global._base        = _base    = process.env.HOME + '/.irac'
global.Tor          = Tor      = require('./js/tor')

global.$ = $

global.Kreem        = Kreem    = require('./js/kreem')
global.Player       = Player   = Kreem.Player
global.Recorder     = Recorder = Kreem.Recorder
global.Stream       = Stream   = Kreem.Stream
global.Peer         = Peer     = Kreem.Peer

cerosine = require './js/cerosine'
global.Text = Text = cerosine.Text
global.eMail = eMail = cerosine.eMail
global.Field = Field = cerosine.Field
global.Dialog = Dialog = cerosine.Dialog
global.Button = Button = cerosine.Button
global.Password = Password = cerosine.Password
global.File = File = cerosine.File

class Storable
  constructor : (@path, @defaults) -> @read()
  read : =>
    try inp = JSON.parse fs.readFileSync @path
    inp = {} unless inp?
    inp[k] = v for k,v of @defaults when not inp[k]?
    @[k] = v for k,v of inp
  save : =>
    out = {}
    out[k] = v for k,v of @ when typeof v isnt 'function' and k isnt 'path' and k isnt 'defaults'
    fs.writeFileSync @path, JSON.stringify out

global.Settings = Settings = new Storable _base + '/user.json', name : 'anonymous'
Settings.nick = optimist.argv.nick if optimist.argv.nick?


Tor.start ->
  optimist = require 'optimist'
  listen = Kreem.listen
    addr   : '0.0.0.0'
    port   : optimist.argv.port || 33023
    nick   : Settings.nick
    pubkey : 'lolcats'

$(document).ready ->
  $('body').append '<div id="dialogs"></div>'
  Dialog.frame = $('#dialogs')

  update_profile = ->
    $('#profile > .nick').html Settings.nick
    $('#profile > .avatar').attr 'src', 'file://' + Settings.avatarPath
  update_profile()

  # Recorder (logo button)
  ptt = $('#logo').on 'click', -> Recorder.toggle()
  Recorder.on 'start', -> ptt.addClass 'down'
  Recorder.on 'stop',  -> ptt.removeClass 'down'

  # 'Add Buddy' Dialog
  addBuddy = new Dialog
    id : 'addBuddy'
    form : buddyAddress : type : eMail, title : 'Buddy Address'
    btn :
      cancel  : title : 'Cancel',    click : -> @toggle()
      default : title : 'Add Buddy', click : ->
        Kreem.connect addBuddy.$.find("input").val()
        @toggle()
  add = $('#add').on 'click', -> addBuddy.toggle()

  # 'Settings' Dialog
  settings = new Dialog
    id : 'settings'
    form :
      nick   : type : Text, value: Settings.nick, title : 'Public Nickname'
      avatar : type : File, title : 'Avatar'
    btn :
      cancel  : title : 'Cancel', click : -> @toggle()
      default : title : 'Save',   click : ->
        Settings.nick = @$.find('#nick').val()
        files = @$.find('input[type="file"]')[0].files
        ext = files[0].path.split('.').pop()
        copy = (src,dst) -> fs.createReadStream(src).pipe(fs.createWriteStream(dst))
        copy files[0].path, path = _base + "/avatar.#{ext}"
        Settings.avatarPath = path
        update_profile()
        Settings.save(); @toggle()
  add = $('#settings').on 'click', -> settings.toggle()

  # 'Upload' Dialog
  upload = new Dialog
    id : 'upload'
    form :
      nick   : type : Text, title : 'Title'
      avatar : type : File, title : 'Avatar'
    btn :
      cancel  : title : 'Cancel', click : -> @toggle()
      default : title : 'Save',   click : ->
  add = $('#upload').on 'click', -> upload.toggle()

  # Handle Kreem's events
  History = $ '#history'
  Buddys  = $ '#buddys'
  Kreem.on 'connection', (info) ->
    History.prepend """
      <div class="message" data-onion="#{info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <span class="nick">#{info.user}</span>
        <span class="text">(connected)</span>
      </div>"""
    Buddys.append """
      <span class="buddy" data-onion="#{info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <span class="nick">#{info.user}</span>
      </span>"""
  Kreem.on 'message', (info, message) -> History.prepend """
    <div class="message" data-onion="#{info.onion}">
      <img  class="avatar" src="img/anonymous.svg" />
      <span class="nick">#{info.user}</span>
      <span class="text">#{message}</span>
    </div>"""

###
  l.push { id : id, nick : p.info.user, ip : p.remoteAddress } for id, p of Peer.byId
  Api.send buddy : list : '#all'
  Api.register buddy : list : (buddys) ->
    list = $ '#buddys'
    list.append """
      <div class='buddy'>
        <img src="img/buddy/#{b.nick}.png" />
        <span class='nick'>#{b.nick}</span>
        <span class='ip'>#{b.ip}</span>
      </div>
    """ for id, b of buddys
###