###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

global.$ = $
global.GUI = true
global.gui = require 'nw.gui'

require './js/common'

{ _base, gui, colors, optimist, fs, ync, shell, Tor, Kreem, Player, Recorder, Stream, Settings, Peer } = global

global.cerosine = cerosine = require './js/cerosine'
Text     = cerosine.Text
eMail    = cerosine.eMail
Field    = cerosine.Field
Dialog   = cerosine.Dialog
Button   = cerosine.Button
Password = cerosine.Password
File     = cerosine.File
Numeric  = cerosine.Numeric
Progress = cerosine.Progress

console.log '[', 'gui'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow, _base

console.log "WK_base:", _base

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

Kreem.init -> Kreem.listen()

$(document).ready ->
  $('body').append '<div id="dialogs"></div>'
  Dialog.frame = $('#dialogs')

  update_profile = ->
    $('#profile > .nick').html Settings.name
    $('#profile > .address').html Settings.onion + ':' + Settings.port
    $('#profile > .avatar').attr 'src', 'file://' + Settings.avatarPath

  # Recorder (logo button)
  ptt = $('#logo').on 'click', -> Recorder.toggle()
  Recorder.on 'start', -> ptt.addClass 'down'
  Recorder.on 'stop',  -> ptt.removeClass 'down'

  # 'Add Buddy' Dialog
  addBuddy = new Dialog
    id : 'addBuddy'
    form : buddyAddress : type : eMail, title : 'Buddy Address', value : 'localhost:33023'
    btn :
      cancel  : title : 'Cancel',    click : -> @toggle()
      default : title : 'Add Buddy', click : ->
        Kreem.connect_raw addBuddy.$.find("input").val()
        @toggle()
  add = $('#add').on 'click', -> addBuddy.toggle()

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

  init_progress = new Progress title : 'Connecting', frame : History
  # Kreem.on 'tor.log', (line) -> console.log line 
  #Kreem.on 'init.confdir', -> init_progress.value 5

  Kreem.on 'init.readconf', ->
    init_progress.value 10
    update_profile()
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
          debugger
          files = @$.find('input[type="file"]')[0].files
          Settings.avatarPath = files[0].path if files.length > 0
          Settings.save => @toggle null, update_profile()
    add = $('#settings').on 'click', -> settings.toggle()

  Kreem.on 'error', ->
  Kreem.on 'init.otr', -> init_progress.value 10
  Kreem.on 'init.otr.done', -> init_progress.value 15
  Kreem.on 'tor.checkport', -> init_progress.value 22
  Kreem.on 'tor.updaterc', -> init_progress.value 24
  Kreem.on 'tor.start', -> init_progress.value 26
  Kreem.on 'tor.log', -> init_progress.value 28
  Kreem.on 'tor.ready', -> init_progress.value 30
  Kreem.on 'init.listen', -> init_progress.value 100
  #Kreem.on 'test.callmyself', -> init_progress.value 50
  #Kreem.on 'test.callmyself.success', -> init_progress.value 70

  Kreem.on 'connection', (info) ->
    History.prepend """
      <div class="message" data-onion="#{info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <span class="nick">#{info.name}</span>
        <span class="text">(connected)</span>
      </div>"""
    Buddys.append """
      <span class="buddy" data-onion="#{info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <span class="nick">#{info.name}</span>
      </span>"""
  Kreem.on 'message', (info, message) -> History.prepend """
    <div class="message" data-onion="#{info.onion}">
      <img  class="avatar" src="img/anonymous.svg" />
      <span class="nick">#{info.name}</span>
      <span class="text">#{message}</span>
    </div>"""
