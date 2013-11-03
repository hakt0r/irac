###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ Stream, Peer, Player, Recorder, EventEmitter, Settings, sha512, OTR } = global

User = null # otr user object

_socket_fail = (socket, reason) -> ->
  socket.end()
  delete Peer.byId[socket.info.id]
  Kreem.emit reason, socket

new_connection = (socket, opts) ->
  _delim = String.fromCharCode(0)
  ses = ctx = null
  info = socket.info = user : 'anonyomus'
  info[k] = v for k,v of info
  info.otr = {}
  __write = socket.write
  _write  = (data) -> __write.call socket, data + _delim, 'utf8'
  socket.on "error",   _socket_fail socket, 'error'
  socket.on "end",     _socket_fail socket, 'disconnected'
  socket.on "timeout", _socket_fail socket, 'timeout'
  inhandler = (data) ->
    data = data.toString('utf8').split ':'
    info.name  = data[0]
    info.onion = data[1]
    info.port  = data[2]
    console.log 'handshake'.red, info.name, info.onion
    info.otr.ctx = ctx = User.ConnContext(Settings.name, "irac", info.name)
    info.otr.ses = ses = new OTR.Session User, ctx, policy: OTR.POLICY("ALWAYS ALLOW_V3 REQUIRE_ENCRYPTION"), MTU : 5000
    ses.on "message", Peer.peerMessage(socket)
    ses.on "create_instag", (accountname,protocol) -> User.generateInstag accountname, protocol, (err,instag) ->
    ses.on "new_fingerprint", (fingerprint) -> console.log fingerprint
    ses.on "inject_message", (data) -> _write data
    ses.on "smp_request", => ses.respond_smp()
    ses.on "gone_secure", => console.log if ses.isAuthenticated() then "secure connexion".green else console.log "insecure connexion".red
    ses.on "still_secure", => console.log if ses.isAuthenticated() then "secure connexion".green else console.log "insecure connexion".red
    ses.on "smp_complete", =>
      User.writeFingerprints()
      console.log if ses.isAuthenticated() then "secure connexion".green else console.log "insecure connexion".red
    socket.write = (data) -> ses.send data
    inhandler =    (data) -> ses.recv data
    Peer.handshake socket
  inbuf = new Buffer []
  socket.on "data", (data) ->
    inbuf = Buffer.concat [inbuf, data]
    while ( msgEnd = inbuf.indexOf(_delim) ) > -1
      msg   = inbuf.toString('utf8', 0, msgEnd)
      inbuf = inbuf.slice msgEnd + 1
      inhandler msg
  Peer.byId[info.id] = socket
  _write Settings.name + ':' + Settings.onion + ':' + Settings.port, 'utf8'
  
socksjs = require "socksjs"
connect = (host='127.0.0.1',port=33023, callback) ->
  if host.indexOf(':') > 0
    [ host, port ] = host.split ':'
    port = parseInt port
  host = host + '.onion' unless host.match 'onion$'
  console.log ['connecting', host, port, Settings.torport].join ' '
  remote_options = host: host, port: port, ssl : yes
  socks_options  = host: "127.0.0.1", port: Settings.torport
  socksjs.connect remote_options, socks_options, (err, socket, info) ->
    callback(err, socket) if callback?
    if err then console.log 'error', host, err
    else new_connection socket, id : Peer.lastid++, onion : host, port : port
    null
  null

connect_raw = (host='127.0.0.1',port=33023, callback) ->
  if host.indexOf(':') > 0
    [ host, port ] = host.split ':'
    port = parseInt port
  console.log ['connecting_raw', host, port].join ' '
  options =
    host : host
    port : port
    rejectUnauthorized : no
    key: fs.readFileSync _base+"/server-key.pem"
    cert: fs.readFileSync _base+"/server-cert.pem"
  socket = require('tls').connect options, (err) ->
    callback(err, socket) if callback?
    unless err
      new_connection socket, id : Peer.lastid++, onion : host, port : port
    else console.log 'error', host, err

listen = (callback) -> Tor.start ->
  tls = require "tls"
  options =
    rejectUnauthorized : no
    key: fs.readFileSync _base+"/server-key.pem"
    cert: fs.readFileSync _base+"/server-cert.pem"
  server = tls.createServer options, (socket) -> new_connection socket, id : Peer.lastid++, onion : '<unknown>', user : '<unknown>'
  server.listen Settings.port, "127.0.0.1"
  Kreem.emit 'init.listen'

connect_self : ->
  _try = ->
    connect Settings.onion + '.onion', Settings.port, (err, socket) ->
      if err then setTimeout _try, 5000
      else
        Kreem.emit 'test.callmyself.success'
        socket.end()
        callback() if callback?
  _try()
  Kreem.emit 'test.callmyself'

_mkdir = (dir, callback) -> fs.exists dir, (exists) -> if exists then callback() else fs.mkdir dir, (result) -> if callback? then callback()

init = (callback) -> new ync.Sync
  config_dir : -> _mkdir _base, @proceed
  temp_dir   : -> _mkdir _base + '/tmp', @proceed
  read_settings : -> Settings.read @proceed
  genkey : -> unless fs.existsSync f = _base + "/server-key.pem" then console.log 'genkey', shell.script """
    openssl genrsa -out #{_base}/server-key.pem 4096""", @proceed else @proceed()
  gencert : -> unless fs.existsSync f = _base + "/server-cert.pem" then console.log 'gencert', shell.script """
    openssl req -new -x509 -subj "/C=XX/ST=irac/L=Kreem/O=IT/CN=asd" -key #{_base}/server-key.pem -out #{_base}/server-cert.pem
  """, @proceed else @proceed()
  read_otr : ->
    Kreem.emit 'init.otr'
    otr_init => @proceed Kreem.emit 'init.otr.done'
  ready : ->
    Kreem.emit 'init.readconf'
    callback() if callback?

otr_init = (callback) -> ## load otr private key / initialize account
  User = new OTR.User
    user : Settings.name
    keys : "#{_base}/otr.keys"      # path to OTR keys file (required)
    fingerprints: "#{_base}/otr.fp" # path to fingerprints file (required)
    instags: "#{_base}/otr.instags" # path to instance tags file (required)
  if User.accounts().length < 1
    console.log "OTR".yellow, "Generating Key"
    User.generateKey Settings.name , "xmpp", (err) ->
      if err
        console.log "OTR".yellow, "something went wrong!", err.message
      else
        console.log "OTR".yellow, "Generated Key Successfully"
        User.writeFingerprints()
        state = User.accounts().shift()
        callback state
  else callback User.accounts().shift()

module.exports =
  connect : connect
  connect_raw : connect_raw
  listen : listen
  init : init
