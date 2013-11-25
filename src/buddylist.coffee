###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ i19, GUI, DOTDIR, connect, gui, optimist, fs, Player, Recorder, Settings, cerosine } = ( api = global.api )
{ HTML, Text, eMail, Field, Dialog, Button, Password, File, Numeric, Progress } = cerosine
$ = api.$

###
  The Buddy list and Buddy-related functions
###

module.exports = class Buddy
  connection : null
  info : null

  @list : null
  @add : => new Dialog
    id : 'addBuddy'
    form : buddyAddress : type : eMail, title : 'Buddy Address', value : 'localhost:33023'
    btn :
      cancel  : title : 'Cancel',    click : -> @toggle()
      default : title : 'Add Buddy', click : ->
        api.connect addr = addBuddy.$.find("input").val()
        Settings.buddy[addr] = {}
        Settings.save()
        @toggle()

  _sendFile = (buddy, name) ->
    chooser = $ "#fileDialog"
    chooser.change (evt) ->
      path = $(this).val()
      feed = api.IRAC.announce 'file/unknown', {a:api.IRAC.byId[buddy.session.onion]}
      s = fs.createReadStream path
      s.on 'data', feed 
    chooser.trigger "click"

  _remove = (buddy, name) ->
    delete Settings.buddy[onion]
    v.remove()
    Settings.save()

  _bless_buddy = (k,v) ->
    v = $ v
    onion = v.attr 'data-onion'
    buddy = Settings.buddy[onion]
    v.on 'click', (evt) ->
      m = new gui.Menu()
      m.append new gui.MenuItem label: onion, enabled : no
      m.append new gui.MenuItem label: 'Open chat', click : -> _openChat buddy
      m.append new gui.MenuItem label: 'Send audio', click : -> _sendAudio buddy
      m.append new gui.MenuItem label: 'Send message', click : -> _sendMessage buddy
      m.append new gui.MenuItem label: 'Send file', click : -> _sendFile buddy
      m.append new gui.MenuItem type:  'separator'
      m.append new gui.MenuItem label: 'Authenticate', click : -> _authenticate buddy
      m.append new gui.MenuItem label: 'Remove buddy', click : -> _remove buddy
      m.popup evt.x, evt.y

  _authenticate = (buddy) ->
    smp = new Dialog
      show : yes
      id : 'smp' + buddy.onion
      form :
        question : type : Text, title : 'Secret Question'
        answer   : type : Text, title : 'Answer'
      btn :
        cancel  : title : 'Cancel', click : -> smp.close()
        default : title : 'Start',  click : ->
          ses = buddy.session.otr.ses
          console.log @$.find('#question').val(), @$.find('#answer').val()
          ses.start_smp_question @$.find('#question').val(), @$.find('#answer').val()
          smp.close()
          progress = new Progress title : 'Authenticating', frame : History
          ses.on 'smp_complete', ->
            progress.remove()
    smp.show()

  $().ready =>
    @list  = $ '#buddys'
    $('#add').on 'click', Buddy.add

    api.on 'buddy.offline', (buddy,info) ->
      b = Buddy.list.find("""span[data-onion="#{info.onion}"]""")
      b.addClass 'offline'
      b.find('.nick').html info.name
      api.history info, '(disconnected)'

    api.on 'buddy.online', (buddy,info) ->
      b = Buddy.list.find("""span[data-onion="#{info.onion}"]""")
      b.removeClass 'offline'
      b.find('.nick').html info.name
      api.history info, '(connected)'
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

    api.on 'init.readconf', ->
      for k,v of Settings.buddy
        name = if v? and v.name? then v.name else ''
        Buddy.list.append """
          <span class="buddy offline" data-onion="#{k}">
            <img  class="avatar" src="img/anonymous.svg" />
            <span class="onion">#{k}</span>
            <span class="nick">#{name}</span>
          </span>"""
      $('#buddys > .buddy').each _bless_buddy
