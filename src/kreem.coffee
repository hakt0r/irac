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
  end : String.fromCharCode 0
  ini : String.fromCharCode 1
  otr : String.fromCharCode 2
  msg : String.fromCharCode 3
  frm : String.fromCharCode 4

  byId : {}
  lastclient : 0

  stream : {}
  laststream : 0
  
  broadcast : (data) -> socket.write data for id, socket of IRAC.byId
  groupcast : (group,data) -> socket.write data for id, socket of group

  announce  : (mime,group) ->
    id = IRAC.laststream++
    group = IRAC.byId unless group?
    socket.write "#{IRAC.msg}#{@id} #{mime}#{IRAC.end}" for id, socket of group 
    (data) ->
      b = new Buffer 17
      b.writeUInt8 0, 0
      b.writeUInt32LE id, 1
      b.writeUInt32LE data.length, 3
      for id, socket of group 
        socket.write b
        socket.write data
      null

  recieve : (id,mime) ->
    p = DOTDIR + '/tmp/' + id
    w = fs.createWriteStream p
    d = cp.spawn('padsp',['opusdec','-'],stdio:['pipe','ignore','ignore'])
    IRAC.stream[id] = s = id:id,path:p,file:w,buffer:0,offset:0,decoder:d

  recieve_frame : (id, data) -> try IRAC.stream[id].file.write msg

  sendotr : (socket) -> (data) ->
    socket.write IRAC.otr + data + IRAC.end

  sockfail : (socket, reason) -> (err) ->
    console.log reason.magenta
    api.emit reason, socket, err
    delete IRAC.byId[socket.info.id]
    socket.end()

new_connection = (err, socket, opts) -> unless err

  ses = ctx = null; id = IRAC.lastclient++

  info = socket.info = id : id, user : 'anonyomus', otr : {}
  info[k] = v for k,v of info

  socket.on "error",   IRAC.sockfail socket, 'error'
  socket.on "end",     IRAC.sockfail socket, 'disconnected'
  socket.on "timeout", IRAC.sockfail socket, 'timeout'

  inbuf = new Buffer []
  frameSize = 0
  streamId  = 0

  iracfrmp = (data) ->
    inbuf = Buffer.concat [inbuf, data]
    while ( msgEnd = inbuf.indexOf(IRAC.end) ) > -1
      type  = inbuf.toString 'utf8', 0, 1
      msg   = inbuf.slice 1, msgEnd
      inbuf = inbuf.slice msgEnd + 1
      protocol.frmhandler type, msg
    null

  iracinip = (type, data) ->
    IRAC.sockfail(socket,'protocol_error') 'Malformed Handshake' unless type is IRAC.ini
    protocol.frmhandler = iracctlp
    msg = data.toString('utf8').split ':'
    info.name = msg[0]; info.onion = msg[1]+':'+msg[2]; 
    # Set up OTR
    info.otr.ctx = ctx = User.ConnContext(Settings.name, "irac", info.name)
    info.otr.ses = ses = new OTR.Session User, ctx, policy: OTR.POLICY("ALWAYS ALLOW_V3 REQUIRE_ENCRYPTION"), MTU : 5000
    ses.on "create_instag", (accountname,protocol) -> User.generateInstag accountname, protocol, ((err,instag) ->)
    ses.on "new_fingerprint", (fingerprint) -> console.log fingerprint
    ses.on "message", (data) -> iracfrmp new Buffer data
    ses.on "inject_message", IRAC.sendotr(socket)
    ses.on "smp_request", => ses.respond_smp()
    ses.on "gone_secure", =>
      console.log if ses.isAuthenticated() then "secure connexion".green else console.log "insecure connexion".red
    ses.on "still_secure", =>
      console.log if ses.isAuthenticated() then "secure connexion".green else console.log "insecure connexion".red
    ses.on "smp_complete", =>
      User.writeFingerprints()
      console.log if ses.isAuthenticated() then "secure connexion".green else console.log "insecure connexion".red
    socket.otr = (data) -> ses.send data
    socket.otr IRAC.ini + 'PEER 0.9/KREEM' + IRAC.end
    null

  iracctlp = (type, data) ->
    switch type
      when IRAC.otr then ses.recv data.toString 'utf8'
      when IRAC.ini
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
        api.emit 'stream', socket, id, mime
        api.emit 'stream.' + mime, socket, id, mime
      when IRAC.frm
        protocol.msghandler = iracbinp
        streamId = info.name + data.readUInt32LE 1
        frameSize = data.readUInt32LE 3
      else console.log 'iracctlp error '.red + 'type not recognized: '.yellow + type

  iracbinp = (data) ->
    inbuf = Buffer.concat [inbuf, data]
    null unless inbuf.length > frameSize
    msg = inbuf.slice 0, frameSize
    inbuf = inbuf.slice frameSize
    protocol.msghandler = iracfrmp
    IRAC.recieve_frame streamId, msg

  protocol = 
    msghandler : iracfrmp
    frmhandler : iracinip

  socket.on "data", (data) -> protocol.msghandler data
  socket.write IRAC.ini + Settings.name + ':' + Settings.onion + ':' + Settings.port + IRAC.end, 'utf8'
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
    else j.join()
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