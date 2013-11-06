###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

colors = require 'colors'
require('./js/common') { $ : $, GUI : true, gui : require 'nw.gui' }

{ GUI, DOTDIR, connect, gui, optimist, fs, ync, shell, Tor, Player, Recorder, Settings } = ( api = global.api )

api.cerosine = cerosine = require './js/cerosine'

{ Text, eMail, Field, Dialog, Button, Password, File, Numeric, Progress } = cerosine

console.log '[ gui ] irac/v0.9-kreem', DOTDIR

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

update_profile = ->
  $('#profile > .nick').html Settings.name
  $('#profile > .address').html Settings.onion + ':' + Settings.port
  $('#profile > .avatar').attr 'src', 'file://' + Settings.avatarPath


$(document).ready ->
  api.init api.listen

  # Recorder (logo button)
  ptt = $('#logo').on 'click', -> Recorder.toggle()
  Recorder.on 'start', -> ptt.addClass 'down'
  Recorder.on 'stop',  -> ptt.removeClass 'down'

  # 'Add Buddy' Dialog
  Buddys  = $ '#buddys'

  addBuddy = new Dialog
    id : 'addBuddy'
    form : buddyAddress : type : eMail, title : 'Buddy Address', value : 'localhost:33023'
    btn :
      cancel  : title : 'Cancel',    click : -> @toggle()
      default : title : 'Add Buddy', click : ->
        api.connect addr = addBuddy.$.find("input").val()
        Settings.buddy[addr] = {}
        Settings.save()
        @toggle()
  add = $('#add').on 'click', -> addBuddy.toggle()

  api.on 'connection', (info) ->
    Buddys.find("""span[data-onion="#{info.onion}"]""").removeClass 'offline'
    History.prepend """
      <div class="message" data-onion="#{info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <span class="nick">#{info.name}</span>
        <span class="text">(connected)</span>
      </div>"""

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

  # Handle api's events
  History = $ '#history'

  api.on 'error', console.error

  api.on 'init.firsttimesetup', (callback) -> firsttimesetup = new Dialog
    id : 'firsttimesetup'
    show : yes
    form :
      nick    : type : Text, value: Settings.name,    title : 'Nickname (public pseudonym)'
      avatar  : type : File, title : 'Avatar'
      port    : type : Numeric, value: Settings.port,    title : 'irac Port (33023)'
      torport : type : Numeric, value: Settings.torport, title : 'tor proxy Port (9051)'
      onion   : type : Text,    value: '', title : 'irac-id     (optional)'
      privkey : type : Text,    value: '', title : 'Private key (optional)'
      cert    : type : Text,    value: '', title : 'Certificate (optional)'
    btn :
      cancel  : title : 'Cancel', click : -> process.exit 1
      default : title : 'Save',   click : ->
        Settings.ssl      = {} unless Settings.ssl?
        Settings.name     = @$.find('#nick').val()
        Settings.onion    = val unless (val = @$.find('#torport').val()) isnt ''
        Settings.port     = parseInt @$.find('#port').val()
        Settings.torport  = parseInt @$.find('#torport').val()
        Settings.ssl.key  = val unless (val = @$.find('#torport').val()) isnt ''
        Settings.ssl.cert = val unless (val = @$.find('#torport').val()) isnt ''
        files = @$.find('input[type="file"]')[0].files
        Settings.avatarPath = files[0].path if files.length > 0
        Settings.save => @close null, update_profile()

  init_progress = new Progress title : 'Connecting to network...', frame : History
  # api.on 'tor.log', (line) -> console.log line 
  #api.on 'init.confdir', -> init_progress.value 5

  api.on 'init.readconf', ->
    init_progress.value 10, 'init.readconf'

    update_profile()

    for k,v of Settings.buddy
      Buddys.append """
        <span class="buddy offline" data-onion="#{k}">
          <img  class="avatar" src="img/anonymous.svg" />
          <span class="nick">#{k}</span>
        </span>"""

    # 'Settings' Dialog
    settings = new Dialog
      id : 'settings'
      form :
        nick    : type : Text,    value: Settings.name,    title : 'Public Nickname'
        port    : type : Numeric, value: Settings.port,    title : 'irac Port (33023)'
        torport : type : Numeric, value: Settings.torport, title : 'tor proxy Port (9051)'
        privkey : type : Text,    value: Tor.readOnion() , title : 'Your ID'
        onion   : type : Text,    value: Tor.readKey(),    title : 'Your Private Key'
        avatar  : type : File,                             title : 'Avatar'
      btn :
        cancel  : title : 'Cancel', click : -> @toggle()
        default : title : 'Save',   click : ->
          Settings.name    = @$.find('#nick').val()
          Settings.port    = parseInt @$.find('#port').val()
          Settings.torport = parseInt @$.find('#torport').val()
          files = @$.find('input[type="file"]')[0].files
          Settings.avatarPath = files[0].path if files.length > 0
          Settings.save => @toggle null, update_profile()
    add = $('#settings').on 'click', -> settings.toggle()

  state = # hehe
   'init.otr' : 10
   'init.otr.done' : 15
   'tor.checkport' : 22
   'tor.updaterc' : 24
   'tor.start' : 26
   'tor.ready' : 30
   'init.listen' : 40
   'test.callmyself' : 50
   'test.callmyself.success' : 100
  hookstate = (k,v) -> api.on k, -> init_progress.value v,k
  hookstate k,v for k,v of state

  api.on 'tor.log', (args...) -> console.debug args.join ' '

  api.on 'message', (info, message) -> History.prepend """
    <div class="message" data-onion="#{info.onion}">
      <img  class="avatar" src="img/anonymous.svg" />
      <span class="nick">#{info.name}</span>
      <span class="text">#{message}</span>
    </div>"""

  api.on 'stream', (info, id, mime) -> History.prepend """
    <div class="message" data-onion="#{info.onion}">
      <img  class="avatar" src="img/anonymous.svg" />
      <span class="nick">#{info.name}</span>
      <span class="text">#started streaming #{mime}</span>
    </div>"""
