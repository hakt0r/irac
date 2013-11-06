###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{
  Tor, Player, Recorder, EventEmitter, ync, DOTDIR, fs,
  Settings, sha512, mkdir, shell, cp, OTR
} = ( api = global.api )

User = null # otr user object

# BufferStream = require('bufferstream')

IRAC = 
  ini : 1
  otr : 2
  msg : 3
  frm : 4

  byId : {}
  lastclient : 0

  stream : {}
  laststream : 0

  message : (type, id, data) ->
    # console.log 'msg:'+type+':'+data.length
    b = new Buffer 9 + data.length
    b.writeUInt8 type, 0
    b.writeUInt32LE data.length, 1
    b.writeUInt32LE (if id? id else 0), 5
    b.write data, 9
    b

  broadcast : (data) -> socket.write data for id, socket of IRAC.byId
  groupcast : (group,data) -> socket.write data for id, socket of group

  announce  : (mime,group) ->
    id = IRAC.laststream++
    group = IRAC.byId unless group?
    head = IRAC.message(IRAC.msg, null, new Buffer "#{@id} #{mime}")
    socket.write message for id, socket of group 
    b = new Buffer 9
    b.writeUInt8 IRAC.frm, 0
    b.writeUInt32LE id, 5
    (data) ->
      for id, socket of group
        b.writeUInt32LE data.length, 1
        socket.write b
        socket.write data
      null

  recieve : (id,mime) ->
    p = DOTDIR + '/tmp/' + id
    w = fs.createWriteStream p
    d = cp.spawn('padsp',['opusdec','-'],stdio:['pipe','ignore','ignore'])
    IRAC.stream[id] = s = id:id,path:p,file:w,buffer:0,offset:0,decoder:d

  rcvframe : (id, data) -> try IRAC.stream[id].file.write msg

  sockfail : (socket, reason) -> (err) ->
    console.log reason.magenta + ' ' + err
    # api.emit reason, socket, err
    delete IRAC.byId[socket.info.id]
    socket.end()

new_connection = (err, socket, opts) -> unless err
  pt = {}
  inbuf = new Buffer []
  ses = ctx = binbuf = null
  id = IRAC.lastclient++

  info = socket.info = id : id, user : 'anonyomus', otr : {}
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
      # console.log type + '@' + len + ":" + inbuf.length
      if seek = inbuf.length >= len + 9
        msg   = inbuf.slice 9, len + 9
        inbuf = inbuf.slice len + 9
        if type is IRAC.frm
          pt.msghandler = iracbinp
          binbuf = []
          binbuf.total = 0
          binbuf.streamId = info.name + data.readUInt32LE 1
          binbuf.frameSize = data.readUInt32LE 5
          null
        else
          # console.log "frm".yellow + ' ' + msg.length + ' ' + msg.toString 'utf8'
          pt.frmhandler type, msg
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
    OTR.debugOn()
    IRAC.sockfail(socket,'protocol_error') 'Malformed Handshake: ' + type unless type is IRAC.ini
    pt.frmhandler = iracctlp
    msg = data.toString('utf8').split ':'
    info.name = msg[0]; info.onion = msg[1]+':'+msg[2]; 
    # Register
    IRAC.byId[info.onion] = info
    console.log 'new otr session with '.blue + info.name
    # Set up OTR
    info.otr.ctx = ctx = User.ConnContext(Settings.name, "irac", info.name)
    info.otr.ses = ses = new OTR.Session User, ctx,
      policy: OTR.POLICY("ALWAYS") + OTR.POLICY('REQUIRE_ENCRYPTION')
      MTU : 5000
    ses.on "error", console.log
    ses.on "message", (data) ->
      #console.log data.cyan
      iracctlp data.charCodeAt(0), data.substr(1)
    ses.on "inject_message", (data) -> socket.write IRAC.message(IRAC.otr,null,data)

    ses.on "msg_event", (num,msg,err) ->
      #console.log OTR.MSGEVENT(num).red + ": " + msg + ':' + err
      ses.connect()

    ses.on "create_instag", (accountname,protocol) ->
      #console.log 'Create instag for '.red + accountname, protocol
      User.generateInstag accountname, protocol, (err,tag) ->
        console.log 'Created instag for '.green + accountname, protocol

    ses.on "create_privkey", (accountname,protocol) ->
      #console.log 'Create privkey for '.red + accountname, protocol
      User.generateKey accountname, protocol, (err,tag) ->
        console.log 'Created privkey for '.green + accountname, protocol

    ses.on "new_fingerprint", (fingerprint) ->
      # console.log 'FINGERPRINT '.yellow + fingerprint
      User.writeFingerprints()
    ses.on "smp_request", -> ses.respond_smp()

    _sec = (evt,call) -> ses.on evt, ->
      console.log evt.red + '########################################################'.blue
      console.log evt.red, if ses.isAuthenticated() then "secure connexion".green else "insecure connexion".red
      call() if call?
    _sec 'gone_secure', -> ses.send String.fromCharCode(IRAC.ini) + 'PEER 0.9/KREEM'
    _sec 'still_secure'

    ses.on "smp_complete", -> User.writeFingerprints()
    socket.otr = (data) -> ses.send data
    setTimeout (-> ses.connect()), 2000
    null

  iracctlp = (type, data) ->
    # console.log 'ctl'.red + ':' + type + ':' + data
    switch type
      when IRAC.otr then ses.recv data.toString 'utf8'
      when IRAC.ini
        # console.log 'helo'.green
        msg = data.toString('utf8').split ' '
        info.class   = msg.shift()
        info.version = msg.shift()
        info.socket  = socket
        IRAC.byId[info.id] = socket
        api.emit 'connection', info
      when IRAC.msg
        msg = data.toString('utf8').split ' '
        id = info.name + parseInt msg[0]; mime = msg[1]
        IRAC.recieve id, mime
        api.emit 'stream',         info, id, mime
        api.emit 'stream.' + mime, info, id, mime
      else
        console.log 'iracctlp error '.red + 'type not recognized: '.yellow + type
        process.exit 255

  pt.msghandler = iracfrmp
  pt.frmhandler = iracinip
  socket.on "data", (data) -> pt.msghandler data
  socket.write IRAC.handshake
  null

###
  TLS server for incoming connections
###

listen = (callback) -> Tor.start ->
  tls = require "tls"
  options = rejectUnauthorized : no, key: Settings.ssl.key, cert: Settings.ssl.cert
  server = tls.createServer options, (socket) -> new_connection null, socket
  server.listen Settings.port, "127.0.0.1"
  api.emit 'init.listen'
  connect_self()
  _try = (k) ->
    connect k, null, (success) ->
      if success
        setTimeout ( -> _try k ), Settings.reconnect_interval
      false
  _try k for k,v of Settings.buddy
  callback() if callback?
  null

###
  SSL-SOCKS powered by socksjs
###

socksjs = require "socksjs"
connect = (host='127.0.0.1',port=33023, callback) ->
  ( [ host, port ] = host.split ':'; port = parseInt port ) if host.indexOf(':') > 0
  console.log ['connecting', host, port, Settings.torport].join ' '
  host = host + '.onion' unless host.match 'onion$'
  onion = host.replace(/.onion$/,'')+(if port isnt 33023 then ':' + port else '')
  remote_options = host: host, port: port, ssl : yes
  socks_options  = host: "127.0.0.1", port: Settings.torport
  socket = new socksjs remote_options, socks_options
  socket.on 'connect', (err) ->
    return if callback? and callback false, socket
    new_connection err, socket, onion : onion, port : port
  socket.on 'error', ->
    callback true if callback?
    console.log host
  api.emit 'test.callmyself'
  null

###
  RAW tls client connect for debug purposes
###

connect_raw = (host='127.0.0.1',port=33023, callback) ->
  ( [ host, port ] = host.split ':'; port = parseInt port ) if host.indexOf(':') > 0
  callback = ( (err) -> new_connection err, socket, onion : host, port : port ) unless callback?
  console.log ['connecting_raw'.red, host, port].join ' '
  options = host : host, port : port, rejectUnauthorized : no, key: Settings.ssl.key, cert: Settings.ssl.cert
  socket = require('tls').connect options, callback

###
  Self connect test via tor for the init process and later maybe regular checks
###

connect_self = (callback) -> 
  _try = ->
    connect Settings.onion + '.onion', Settings.port, (err, socket) ->
      if err then setTimeout _try, 5000 else
        api.emit 'test.callmyself.success'
        socket.end()
        callback true if callback?
      true
  api.emit 'test.callmyself'
  _try()

###
  The Mighty init sync
###

init = (callback=(->)) -> new ync.Sync
  config_dir    : -> mkdir DOTDIR, (firstboot) => @firstboot = firstboot; @proceed()
  read_settings : -> Settings.read @proceed
  # config_dir_setup : -> unless @firstboot and api.GUI then @proceed() else api.emit 'init.firstboot', @proceed 
  apply_settings : ->
    msg = Settings.name + ':' + Settings.onion + ':' + Settings.port
    console.log '[' + msg.red + ']'
    IRAC.handshake = IRAC.message(IRAC.ini, null, msg)
    @proceed()
  config_dir_read  : ->
    Settings.ssl = {} unless Settings.ssl?
    j = new ync.Join true
    j.part mkdir DOTDIR + '/tmp', j.join
    unless Settings.ssl.key? and Settings.ssl.cert? # bootsrap and read ssl keys
      j.part()
      ssl = new ync.Sync
        fork : yes
        generate_key : -> 
          console.log 'Generating ssl key: '.red + DOTDIR.yellow
          Settings.ssl.cert = undefined
          shell.script "openssl genrsa -out #{DOTDIR}/server-key.pem 4096", (status,err) ->
            console.log status + err
            ssl.proceed Settings.ssl.key = fs.readFileSync DOTDIR + "/server-key.pem", 'utf8'
        generate_crt : -> if Settings.ssl.cert? then ssl.proceed() else
          console.log 'Generating ssl cert: '.red + DOTDIR.yellow
          shell.script """
            openssl req -new -x509 -subj "/C=XX/ST=irac/L=api/O=IT/CN=#{Settings.onion}" -key #{DOTDIR}/server-key.pem -out #{DOTDIR}/server-cert.pem
          """, =>
            ssl.proceed Settings.ssl.cert = fs.readFileSync DOTDIR + "/server-cert.pem", 'utf8'
            Settings.save()
        done : -> j.join console.log 'ssl keyread done'
    j.part() ## load otr private key / initialize account
    api.emit 'init.otr'
    User = new OTR.User
      user : Settings.name
      keys : "#{DOTDIR}/otr.keys"      # path to OTR keys file (required)
      fingerprints: "#{DOTDIR}/otr.fp" # path to fingerprints file (required)
      instags: "#{DOTDIR}/otr.instags" # path to instance tags file (required)
    if User.accounts().length < 1
      console.log "OTR".yellow, "Generating Key"
      User.generateKey Settings.name , "xmpp", (err) ->
        if err then console.log "OTR".yellow, "Something went wrong!", err.message
        else
          console.log "OTR".yellow, "Generated Key Successfully"
          j.join User.writeFingerprints()
          api.emit 'init.otr.done'
    else j.join api.emit 'init.otr.done'
    j.end @proceed
  ready : ->
    api.emit 'init.readconf'
    callback() if callback?

module.exports =
  init : init
  listen : listen
  connect : connect
  connect_raw : connect_raw
  IRAC : IRAC
  User : User