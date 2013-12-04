###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ $, Tor, i19, GUI, gui, DOTDIR, connect, gui, optimist, fs, Player, Recorder, Settings, cerosine } = ( api = global.api )
{ HTML, Text, eMail, Field, Dialog, Button, Password, File, Numeric, Progress } = cerosine

class UI
  @settings : ->
    _reset = ->
      dlg.$.find('#nick').val Settings.name
      dlg.$.find('#port').val Settings.port
      dlg.$.find('#key').val Tor.key
      dlg.$.find('#onion').val Tor.onion
      f = dlg.$.find('input[type="file"]')[0].files
      f.clear()
      f.append Settings.avatarPath
    dlg = new Dialog
      id : 'settings'
      frame : $ '#main > .tab-content'
      className : 'tab-pane'
      hidden : no
      form :
        nick   : type : Text,    value: Settings.name, title : 'Public Nickname'
        port   : type : Numeric, value: Settings.port, title : 'irac Port (33023)'
        onion  : type : Text,    value: Tor.onion,     title : 'Your ID'
        key    : type : Text,    value: Tor.key,       title : 'Your Private Key'
        avatar : type : File,                          title : 'Avatar'
      btn :
        cancel  : title : 'Cancel', click : -> _reset()
        default : title : 'Save',   click : ->
          Settings.name = @$.find('#nick').val()
          Settings.port = parseInt @$.find('#port').val()
          files = @$.find('input[type="file"]')[0].files
          Settings.avatarPath = files[0].path if files.length > 0
          api.update_profile()
          Settings.save ->

api.on 'init.readconf', ->
  UI.settings()
  $().tab()
  $('#main a[href="#settings"]').tab('show')

###
  The Buddy list and Buddy-related functions
###

class Buddy
  connection : null
  info : null

  constructor : (@info) ->
    console.log @info
    Buddy.list.append """
      <span class="buddy offline" data-onion="#{@info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <img  class="trust" src="img/otr_enc.svg" />
        <span class="onion">#{@info.onion}</span>
        <span class="nick">#{@info.name}</span>
      </span>"""
    m = new gui.Menu()
    m.append new gui.MenuItem label: @info.onion, enabled : no
    m.append new gui.MenuItem label: 'Open chat', click : @openChat
    #m.append new gui.MenuItem label: 'Send audio', click : @sendAudio
    #m.append new gui.MenuItem label: 'Send message', click : @sendMessage
    m.append new gui.MenuItem label: 'Send file', click : @sendFile
    m.append new gui.MenuItem type:  'separator'
    m.append new gui.MenuItem label: 'Authenticate', click : @authenticate
    m.append new gui.MenuItem label: 'Remove buddy', click : @remove
    @$ = $ Buddy.list.find('span.buddy').toArray().pop()
    @$.on 'click', (evt) -> m.popup evt.x, evt.y

  openChat : =>
    api.once 'chatwindow', (win) => win.init @
    win = gui.Window.open 'chat.html', position: 'center' #, toolbar : no

  sendFile : =>
    chooser = $ "#fileDialog"
    chooser.change (evt) =>
      path = $(this).val()
      feed = api.IRAC.announce 'file/unknown', {a:api.IRAC.byId[@session.onion]}
      s = fs.createReadStream path
      s.on 'data', feed 
    chooser.trigger "click"

  remove : => if window.confirm 'Are you sure?'
    @$.remove()
    delete Buddy.byId[@info.onion]
    delete Settings[@info.onion]
    Settings.save()

  authenticate : => smp = new Dialog
    hidden : no
    id : 'smp' + @onion
    form :
      question : type : Text, title : 'Secret Question'
      answer   : type : Text, title : 'Answer'
    btn :
      cancel  : title : 'Cancel', click : -> smp.close()
      default : title : 'Start',  click : =>
        ses = @session.otr.ses
        console.log @$.find('#question').val(), @$.find('#answer').val()
        ses.start_smp_question @$.find('#question').val(), @$.find('#answer').val()
        smp.close()
        progress = new Progress title : 'Authenticating', frame : History
        ses.on 'smp_complete', =>
          progress.remove()

  trusted : (info) =>
    @$.find('.trust').attr 'src', 'img/otr_auth.svg'

  connected : (info) =>
    @info = info if info?
    @$.removeClass 'offline'
    @$.find('.nick').html info.name
    api.history info, '(connected)'
    info.otr.ses.removeAllListeners 'smp_request'
    info.otr.ses.on 'smp_request', (question) ->
      smp = new Dialog
        show : yes
        id : 'smp' + buddy.onion
        form :
          question : type : HTML, title : 'Secret Question', value : question
          answer   : type : Text, title : 'Answer'
        btn :
          cancel  : title : 'Cancel', click : -> smp.close()
          default : title : 'Start',  click : ->
            ses = buddy.session.otr.ses
            ses.respond_smp @$.find('#answer').val()
            smp.close()
            progress = new Progress title : 'Authenticating', frame : History
            ses.on 'smp_complete', -> progress.remove()
      smp.show()

  disconnected : =>
    @$.addClass 'offline'
    @$.find('.nick').html @info.name
    api.history @info, '(disconnected)'

  @byId : {}
  @list : null
  
  @add : => new Dialog
    onetime : true
    form : addr : type : eMail, title : 'Buddy Address', value : 'localhost:33023'
    btn :
      cancel  : title : 'Cancel',    click : -> @close()
      default : title : 'Add Buddy', click : ->
        api.connect addr = addBuddy.$.find("input").val()
        Settings.buddy[addr] = {}
        Settings.save()
        @close()

  $(undefined).ready =>
    Buddy.list = $ '#buddys'

    $('#add').on 'click', Buddy.add

    api.on 'init.readconf', ->
      for k,v of Settings.buddy
        v.onion = k unless v.onion?
        Buddy.byId[k] = new Buddy v

    api.on 'buddy.offline', (buddy,info) -> Buddy.byId[info.onion].disconnected info
    api.on 'buddy.online',  (buddy,info) -> Buddy.byId[info.onion].connected info
    api.on 'buddy.trusted', (buddy,info) -> Buddy.byId[info.onion].trusted info

module.exports = 
  UI : UI
  Buddy : Buddy