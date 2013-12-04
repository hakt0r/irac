
gui = require 'nw.gui'
win = gui.Window.get()

api = global.api
{ Settings } = api

win.showDevTools() if api.debug

win.init = (buddy) ->
  info = buddy.info
  win.buddy = buddy
  win.title = "[#{info.onion}] irac:chat"
  api.on 'pmsg.' + info.onion, (msg) ->
    win.remote msg

$().ready ->
  History = $('#history')
  win.log = (message) -> History.prepend """
    <div class="message"><span class="nick">notice</span><span class="text">#{message}</span></div>"""
  win.myself = (message) -> History.prepend """
    <div class="message">
      <img  class="avatar" src="file://#{Settings.avatarPath}" />
      <span class="nick">#{Settings.name}</span>
      <span class="text">#{message}</span>
    </div>"""
  win.remote = (message) -> History.prepend """
    <div class="message">
      <img  class="avatar" src="file://#{Settings.avatarPath}" />
      <span class="nick">#{win.buddy.info.name}</span>
      <span class="text">#{message}</span>
    </div>"""
  api.emit 'chatwindow', win
  Input = $ '#chat input'
  Input.on 'keydown', (e) ->
    if e.keyCode is 13 or e.keyCode is 10
      win.buddy.info.sendpmsg Input.val()
      win.myself Input.val()
      Input.val('')
