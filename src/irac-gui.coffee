###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

_base = './js'

require( _base + '/common' ) $ : $, GUI : true, gui : require 'nw.gui'

{ i19, GUI, DOTDIR, connect, gui, optimist, fs, ync, Tor, Player, Recorder, Settings } = ( api = global.api )

api.cerosine = cerosine = require _base + '/cerosine'

{ HTML, Text, eMail, Field, Dialog, Button, Password, File, Numeric, Progress } = cerosine

console.log '[ gui ] irac/v0.9-kreem', DOTDIR, _base

tray = new gui.Tray
  title : 'irac'
  icon  : 'img/logo.png'

menu = new gui.Menu();
menu.append new gui.MenuItem type:  'checkbox', label: 'Online'
menu.append new gui.MenuItem type:  'checkbox', label: 'Talk', click : -> Recorder.toggle()
menu.append new gui.MenuItem label: 'Settings', click : -> window.open 'settings.html', '_blank', 'screenX=0,screenY=0,width=100,height=100'
menu.append new gui.MenuItem type:  'separator'
menu.append new gui.MenuItem label: 'Devtools', click : -> gui.Window.get().showDevTools()
menu.append new gui.MenuItem label: 'Always on top', click : -> gui.Window.get().setAlwaysOnTop true
menu.append new gui.MenuItem type:  'separator'
menu.append new gui.MenuItem label: 'Quit', click : -> process.exit(0)
tray.menu = menu

win = gui.Window.get()
gui.main = win
gui.api = api
win.showDevTools()

update_profile = api.update_profile = ->
  $('#profile > .nick').html Settings.name
  $('#profile > .onion').html Settings.onion + ':' + Settings.port
  $('#profile > .avatar').attr 'src', 'file://' + Settings.avatarPath

Buddy = require './js/buddylist'

api.init api.listen

$(document).ready ->
  # History
  History = $ '#history'
  api.history = (info, message) -> History.prepend """
    <div class="message" data-onion="#{info.onion}">
      <img  class="avatar" src="img/anonymous.svg" />
      <span class="nick">#{info.name}</span>
      <span class="text">#{message}</span>
    </div>"""

  # Recorder (logo button)
  ptt = $('#logo').on 'click', -> Recorder.toggle()
  Recorder.on 'start', -> ptt.addClass 'down'
  Recorder.on 'stop',  -> ptt.removeClass 'down'

  # 'Upload' Dialog
  Upload = new Dialog
    id : 'upload'
    form :
      nick   : type : Text, title : 'Title'
      avatar : type : File, title : 'Avatar'
    btn :
      cancel  : title : 'Cancel', click : -> @toggle()
      default : title : 'Save',   click : ->
  $('#upload').on 'click', -> Upload.toggle()

  # Handle api's events
  api.on 'error', console.error
  api.on 'pmsg', api.history

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

  init_progress = new Progress title : 'Start', frame : History
  api.on 'tor.log', (line) -> console.log line
  #api.on 'init.confdir', -> init_progress.value 5

  api.on 'init.readconf', ->
    init_progress.value 10, i19['init.readconf']
    update_profile()

  state =
   'init.checkdir' : 10
   'init.otr' : 10
   'init.otr.done' : 15
   'tor.start' : 22
   'tor.port' : 22
   'tor.conf' : 24
   'init.readconf' : 25
   'tor.ready' : 30
   'init.listen' : 40
   'init.callmyself' : 50
   'init.callmyself.success' : 100

  api.on 'init.callmyself.success', ->
    $('#main a[href="#home"]').tab('show')
  $('#main a[href="#history"]').tab('show')

  hookstate = (k,v) -> api.on k, ->
    # console.debug process.pid + ' [debug] ' + ' ' + k + ' ' + v
    init_progress.value v, i19[k]
  hookstate k,v for k,v of state

  # api.on 'tor.log', (args...) -> console.debug args.join ' '

  api.on 'message', api.history
  api.on 'stream', (info, id, mime) ->
    api.history info, "started streaming #{mime}"
