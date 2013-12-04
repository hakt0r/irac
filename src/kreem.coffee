###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ Tor, Player, Recorder, EventEmitter, ync, DOTDIR, fs,
  Settings, sha512, md5, mkdir, xl, cp, OTR
} = ( api = global.api )

_log = (args...) -> console.log Settings.name.yellow + '] ' + args.concat().join ' '

IRAC =
  ini  : 1
  otr  : 2
  msg  : 3
  frm  : 4
  pmsg : 5
  req  : 6

  byId  : {}
  buddy : {}
  lastclient : 0

  stream : {}
  laststream : 0

  message : (type, id, data) ->
    length = Buffer.byteLength(data, 'utf8')
    b = new Buffer 9 + length
    b.writeUInt8 type, 0
    b.writeUInt32LE length, 1
    b.writeUInt32LE (if id? id else 0), 5
    b.write data, 9
    b

  broadcast : (data) -> socket.write data for id, socket of IRAC.byId
  groupcast : (group,data) -> socket.write data for id, socket of group

  announce  : (mime,group) ->
    group = IRAC.byId unless group?
    id = IRAC.laststream++
    head = IRAC.message IRAC.msg, null, "#{id} #{mime}"
    socket.write head for k, socket of group
    b = new Buffer 9
    b.writeUInt8 IRAC.frm, 0
    b.writeUInt32LE id, 5
    (data) ->
      b.writeUInt32LE data.length, 1
      for id, socket of group
        socket.write b
        socket.write data
      null

  recieve : (id,mime) ->
    p = DOTDIR + '/tmp/' + id
    # _log 'stream'.red, id, mime, p
    w = fs.createWriteStream p
    d = cp.spawn('padsp',['opusdec','-'],stdio:['pipe','ignore','ignore'])
    IRAC.stream[id] = id:id,path:p,file:w,buffer:0,offset:0,decoder:d

  rcvframe : (id, data) ->
    _log 'frame'.red, data.length
    IRAC.stream[id].file.write data
    IRAC.stream[id].decoder.stdin.write data

  sockfail : (socket, reason) -> (err) ->
    _log reason.magenta + ' ' + err
    # api.emit reason, socket, err
    delete IRAC.byId[socket.info.id]
    socket.end()

new_connection = (err, socket, opts) -> unless err
  User = api.User
  pt = {}
  inbuf = new Buffer []
  ses = ctx = binbuf = null
  id = IRAC.lastclient++

  info = socket.info = id : id, name : 'anonyomus', otr : {}
  info[k] = v for k,v of info

  socket.on "error",   IRAC.sockfail socket, 'error'
  socket.on "end",     IRAC.sockfail socket, 'disconnected'
  socket.on "timeout", IRAC.sockfail socket, 'timeout'

  iracfrmp = (data) ->
    seek = yes
    inbuf = Buffer.concat [inbuf, data]
    while seek and inbuf.length > 4
      type = inbuf.readUInt8 0
      len  = inbuf.readUInt32LE 1
      id   = inbuf.readUInt32LE 5
      if seek = inbuf.length >= len + 9
        msg   = inbuf.slice 9, len + 9
        inbuf = inbuf.slice len + 9
        if type is IRAC.frm
          streamId = info.name + id
          IRAC.rcvframe streamId, msg
          null
        else pt.frmhandler type, msg
    null

  iracbinp = (data) ->
    binbuf.total += data.length
    unless binbuf.total >= binbuf.frameSize
      binbuf.push data; null # data is the current frame, not pushed to binbuf, but added to total
    inbuf = if binbuf.total > binbuf.frameSize
        data.slice binbuf.total - data.length + 1
      else new Buffer []
    msg = if binbuf.length > 0
        binbuf.push data.slice 0, binbuf.total - data.length
        Buffer.concat binbuf
      else data.slice 0, binbuf.total - data.length
    IRAC.rcvframe binbuf.streamId, msg
    pt.msghandler = iracfrmp; binbuf = null

  iracinip = (type, data) ->
    IRAC.sockfail(socket,'protocol_error') 'Malformed Handshake: ' + type unless type is IRAC.ini
    pt.frmhandler = iracctlp
    msg = data.toString('utf8').split ':'
    info.name = msg[0]; info.onion = msg[1]+':'+msg[2];
    info.otr.ctx = ctx = User.ConnContext(Settings.onion, "irac", info.onion)
    info.otr.ses = ses = new OTR.Session User, ctx,
      policy: OTR.POLICY("ALWAYS") + OTR.POLICY('REQUIRE_ENCRYPTION')
      MTU : 5000
    ses.on "error", _log
    ses.on "message", (data) -> iracctlp data.charCodeAt(0), data.substr(1)
    ses.on "inject_message", (data) -> socket.write IRAC.message(IRAC.otr,null,data)
    ses.on "msg_event", (num,msg,err) -> _log OTR.MSGEVENT(num).red + ": " + msg + ':' + err
    ses.on "create_instag", (accountname,protocol) -> User.generateInstag accountname, protocol, (err,tag) ->
        User.writeInstags()
    ses.on "create_privkey", (accountname,protocol) -> User.generateKey accountname, protocol, (err,tag) ->
    ses.on "new_fingerprint", (fingerprint) -> User.writeFingerprints()
    _sec = (evt,callback) -> ses.on evt, -> callback() if callback?
    _sec 'gone_secure', ->
      ses.send String.fromCharCode(IRAC.ini) + 'PEER 0.9/KREEM' if parseInt(info.onion,36) > parseInt(Settings.onion,36)
    _sec 'still_secure'
    ses.on "smp_complete", -> User.writeFingerprints()
    socket.otr = (data) -> ses.send data
    info.sendpmsg = (message) -> ses.send String.fromCharCode(IRAC.pmsg) + message
    ses.connect() if parseInt(info.onion,36) < parseInt(Settings.onion,36)
    IRAC.byId[info.onion] = socket
    api.emit 'connection', info # TODO: move to ses.gone_secure :D
    null

  iracctlp = (type, data) ->
    switch type
      when IRAC.otr then ses.recv data.toString 'utf8'
      when IRAC.ini
        msg = data.toString('utf8').split ' '
        info.class   = msg.shift()
        info.version = msg.shift()
        if (b = Settings.buddy[info.onion])?
          unless b.session?
            b.session = info
            sb = Settings.buddy[info.onion]
            sb.name = info.name
            Settings.save ->
              console.log Settings.buddy[info.onion]
              Settings.read ->
                console.log Settings.buddy[info.onion]
            # socket.otr String.fromCharCode(IRAC.req) + 'private/avatar' unless sb.avatar?
            api.emit 'buddy.online', b, info
            if ctx.trust() is 'smp'
              _log "authenticated".green, info.name.yellow, '[', info.onion.blue, ']'
              api.emit 'buddy.trusted', b, info
          else if Settings.onion < info.onion
            _log "Closing connection - already connected to [ #{info.onion.blue} ]".red
            ses.close()
            socket.end()
        if parseInt(info.onion,36) < parseInt(Settings.onion,36)
          _log 'HELO '.blue + info.onion
          socket.otr String.fromCharCode(IRAC.ini) + 'PEER 0.9/KREEM'
        else _log 'HELO '.green + info.onion
      when IRAC.pmsg
        msg = data.toString('utf8')
        api.emit 'pmsg', info, msg
        api.emit 'pmsg.' + info.onion, msg
      when IRAC.msg
        msg = data.toString('utf8').split ' '
        id = info.name + parseInt msg[0]; mime = msg[1]
        IRAC.recieve id, mime
        api.emit 'stream',         info, id, mime
        api.emit 'stream.' + mime, info, id, mime
      else
        _log 'iracctlp error '.red + 'type not recognized: '.yellow + type
        process.exit 255

  pt.msghandler = iracfrmp
  pt.frmhandler = iracinip
  socket.on "data", (data) -> pt.msghandler data
  socket.write IRAC.handshake # if parseInt(info.onion,36) < parseInt(Settings.onion,36)
  null

###
  TLS server for incoming connections
###

class Buddy
  @session : {}
  @connect : (buddy) -> connect buddy, null, (success) ->
    unless success is true
      setTimeout ( ->
        # _log 'reconnect'.red, buddy.yellow
        Buddy.connect buddy ), 5000 # Settings.reconnect_interval
    # console.log 'returning false'.cyan
    false
  @connectAll : -> @connect k for k,v of Settings.buddy

listen = (callback) ->
  tls = require "tls"
  options = rejectUnauthorized : no, key: Settings.ssl.key, cert: Settings.ssl.cert
  server = tls.createServer options, (socket) -> new_connection null, socket
  server.listen Settings.port, "127.0.0.1"
  api.emit 'init.listen'
  connect_self()
  Buddy.connectAll() if Settings.name is 'anx'
  callback() if callback?
  null


[ connect, connect_raw ] = ( ->

  ###
    SSL-SOCKS powered by socksjs
  ###

  socksjs = require "socksjs"
  connect = (host='127.0.0.1',port=33023, callback) ->
    ( [ host, port ] = host.split ':'; port = parseInt port ) if host.indexOf(':') > 0
    host = host + '.onion' unless host.match 'onion$'
    onion = host.replace(/.onion$/,'')+(if port isnt 33023 then ':' + port else '')
    ##return connect_raw '127.0.0.1', port, callback # debug with raw
    _log ['connecting', host, port, Tor.port].join ' '
    remote_options = host: host, port: port, ssl : yes
    socks_options  = host: "127.0.0.1", port: Tor.port
    socket = new socksjs remote_options, socks_options
    onconnect = (err) ->
      unless err
        return if callback(true, socket) is true
        new_connection err, socket, onion : host, port : port
      else
        callback false, err
    socket.on 'connect', (err, socket) -> onconnect err, socket
    socket.on 'error', -> callback false if callback?
    api.emit 'test.callmyself'
    null

  ###
    RAW tls client connect for debug purposes
  ###

  connect_raw = (host='127.0.0.1',port=33023, callback) ->
    ( [ host, port ] = host.split ':'; port = parseInt port ) if host.indexOf(':') > 0
    callback = (->) unless callback?
    _log 'connecting'.yellow,'[','raw'.red,']', host, port
    onconnect = (err) ->
      unless err
        return if callback(true, socket) is true
        new_connection err, socket, onion : host, port : port
      else
        callback false, err
    socket = require('tls').connect { host : host, port : port, rejectUnauthorized : no, key: Settings.ssl.key, cert: Settings.ssl.cert }, onconnect
    socket.once 'error', ->
      _log 'connect'.red,'[','raw'.red,']', host, port
      callback false

  [ connect, connect_raw ] ).call()

###
  Self connect test via tor for the init process and later maybe regular checks
###

connect_self = (callback) ->
  api.on 'init.callmyself.success', callback if callback?
  attempt = ->
    api.emit 'init.callmyself'
    connect Settings.onion + '.onion', Settings.port, (success) ->
      unless success is true
        setTimeout attempt, 5000
        true
      else
        api.emit 'init.callmyself.success', true
        socket.end() if socket?
        true
  setTimeout attempt, 0

module.exports =
  Buddy : Buddy
  listen : listen
  connect : connect
  connect_raw : connect_raw
  IRAC : IRAC