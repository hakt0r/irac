# Load native UI library

gui = require 'nw.gui'


tray = new gui.Tray
  title : 'irac'
  icon  : 'var/theme/logo.png'

menu = new gui.Menu();
menu.append new gui.MenuItem type: 'checkbox', label: 'Online'
menu.append new gui.MenuItem label: 'Settings'
tray.menu = menu

window.Api = Api = new WebApi 'ws://localhost:8081/irac'

Api.connect ->
  ptt = $('#logo').on 'click', ->
    unless ptt.hasClass 'down'
      Api.send ptt : true
    else Api.send ptt : false
  Api.register ptt:
    open : -> ptt.addClass 'down'
    close: -> ptt.removeClass 'down'

  d = new CDialog
    parent : $ 'body'
    id : 'addBuddy'
    title : 'Add Buddy'
    body : html : '<input/>'
    foot : buttons :
      ok : -> d.close Api.send buddy:add: d.$.find("input").val()
      cancel : -> d.close()
  add = $('#add').on 'click', -> d.toggle()

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