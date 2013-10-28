require 'buffertools'

util = require 'util'; _oldp = util.print; _oldc = console.log
util.print  = (args...) -> _oldp.apply util, args
console.log = (args...) -> _oldc.apply util, args

{ Server }   = require '../cerosine/src/server'
{ i19 }      = require '../cerosine/src/cerosine'
sha512       = require '../cerosine/src/sha512'

class Peer
  @byId : {}
  @lastid : 0

  @broadcast : (data) => socket.write data for id, socket of @byId
  @handshake : (peer) -> peer.write "IRAC kreem/0.9 PEER " + @nick + ' ' + @pubkey + "\r\n"

  @handlePeerMessage : (peer) =>
    info      = peer.info = { user : 'anonyomus' }
    buffer    = new Buffer ''
    binary    = no
    frameSize = 0
    stream    = {}
    return (msg) =>
      buffer = Buffer.concat [buffer, msg]
      while true
        if binary 
          if buffer.length > frameSize
            binary = no
            msg    = buffer.slice 0, frameSize
            buffer = buffer.slice frameSize
            Player.frame stream[streamId], msg
            console.log 'binary'.green, frameSize, msg.length
          else break
        else if ( msgEnd = buffer.indexOf('\r\n') ) > -1
          type   = buffer.toString('utf8', 0, 4)
          msg    = buffer.toString('utf8', 5, msgEnd).split ' '
          buffer = buffer.slice msgEnd + 2
          console.log 'ascii'.red, type, msg.length, msg
          switch type
            when 'IRAC'
              info.version = msg.shift()
              info.class   = msg.shift()
              info.user    = msg.shift()
              info.pubkey  = msg.join ' '
            when 'MESG'
              id   = parseInt msg[0]
              mime = msg[1]
              if mime is 'audio/opus'
                stream[id] = id : id, mime : msg[1], socket : peer
            when 'FRME'
              binary = yes
              streamId   = parseInt msg[0]
              frameSize  = parseInt msg[1]
              continue
        else break

class Stream
  @id : 0
  constructor : (@opts={}) ->
    @opts.group = Peer.byId unless @opts.group?
    @id = Stream.id++
    @cast "MESG #{@id} #{@opts.mime}\r\n"
  cast : (data) => socket.write data for id, socket of @opts.group
  feed : (data) =>
    @cast 'FRME ' + @id + ' ' + data.length + '\r\n'
    @cast data

###
  "audio"
###

cp = require 'child_process'

class Player
  @init : =>
    @decoder = cp.spawn 'padsp',['opusdec','-'],stdio:['pipe','ignore','ignore']
    @decoder.on 'end', (error) -> console.log 'decoder'.red, error
  @frame : (stream, msg) =>
    @decoder.stdin.write msg

class Recorder
  @start : ->
    return if @running
    @running = yes
    stream = new Stream mime : 'audio/opus'
    @record = cp.spawn 'arecord',['-c','1','-r','48000','-twav','-'],stdio:['pipe','pipe','ignore']
    encode  = cp.spawn 'opusenc',['--ignorelength','--bitrate','96','-','-'],stdio:['pipe','pipe','ignore']
    @record.stdout.pipe encode.stdin
    encode.stdout.on 'data', stream.feed
  @stop : ->
    return unless @running
    @running = no
    @record.kill('SIGKILL')

Player.init()

###
  Network Implementation
###

SocksFactory = require "socks-factory"

connect = (host='127.0.0.1',port=33023) ->
  if host.indexOf(':') > 0
    [ host, port ] = host.split ':'
    port = parseInt port
  # console.log "connecting".yellow, host + ":" + port
  options =
    proxy:  ipaddress: "127.0.0.1", port: 9050, type: 5
    target: host: host, port: port
    command: "connect"
  SocksFactory.createConnection options, (err, socket, info) ->
    unless err
      Peer.handshake socket
      socket.on "data", Peer.handlePeerMessage socket
      socket.on "error", console.log
      socket.resume()
    else console.log host, err

listen = (opts) ->
  { addr, port, nick, pubkey } = opts
  Peer.nick = nick
  Peer.pubky = pubkey

  router = require("net").createServer (socket) ->
    id = Peer.lastid++
    Peer.byId[id] = socket
    Peer.handshake socket
    socket.on "data", Peer.handlePeerMessage socket
    socket.on "end", ->
      console.log "@" + uname + " disconnected from " + socket.remoteAddress
      Peer.loose uname
      socket.end()
      delete Peer.byId[id]
    socket.on "timeout", ->
      console.log "@" + uname + " timeout from " + socket.remoteAddress
      Peer.loose uname
      socket.end()

  router.listen port, addr
  setTimeout (-> connect 'jt6jfstgkbbahnhe.onion', 33023 if port is 33023), 1000

  ###
    Webinterface
  ###

  global.App = new Server
    project   : "irac"
    subsystem : Peer.handlePeerMessage
    api :
      ptt : (down) -> if down then Recorder.start() else Recorder.stop()
      buddy :
        list : ->
          l = []
          l.push { id : id, nick : p.info.user, ip : p.remoteAddress } for id, p of Peer.byId
          @reply buddy:list: l
        add : (id) -> connect id

    ready : -> console.log 'ui ready'
    js :
      sm2 : 'https://raw.github.com/scottschiller/SoundManager2/master/script/soundmanager2-nodebug-jsmin.js'
      ync : '../../ync/src/ync.coffee'
    template  : """
    <html><head><title>irac[0.9/kreem] - #{nick}</title>
    </head><body>
      <div id="header">
        <img class="avatar" src="#" />
        <span class="nick">#{nick}</span>
        <button id="ptt">Push to Talk</speak>
        <button id="add">Add Buddy</speak>
      </div>
      <div id="buddys"></div>
      <div id="history"></div>
      <div id="chat"><input /></div>
      <link rel='stylesheet' href='var/theme/styles.css' />
    </body>
    </html>"""
    page : coffee : init : ->
      window.Api = Api = new WebApi __apiconf
      Api.connect ->

        ptt = $('#ptt').on 'click', ->
          unless ptt.hasClass 'down'
            Api.send ptt : true
            ptt.addClass 'down'
          else
            Api.send ptt : false
            ptt.removeClass 'down'

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

          
module.exports =
  Stream : Stream
  Peer : Peer
  connect : connect
  listen : listen