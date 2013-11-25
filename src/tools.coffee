###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ Tor, Player, Recorder, EventEmitter, ync, DOTDIR, fs,
  Settings, sha512, md5, mkdir, xl, cp, OTR, IRAC, optimist, os, Xhell, Xcript, Xync, Xoin
} = ( api = global.api )

_install_nodewebkit = (callback) ->
  url = "https://s3.amazonaws.com/node-webkit/v0.7.5/node-webkit-v0.7.5-#{os.type}-#{os.arch}.tar.gz"
  # url = "http://localhost:8080/node-webkit.tar.gz"
  me = new Xync
    title : 'node-webkit'.blue
    download : ->
      if fs.existsSync DOTDIR + '/node-webkit.tar.gz' then @proceed()
      else get = require('https').get url, (res) =>
        oldline = ''
        start = (new Date).getTime()
        length = parseInt res.headers['content-length']
        got = 0
        out = fs.createWriteStream(DOTDIR + '/node-webkit.tar.gz')
        res.on 'data', (data) =>
          now = (new Date).getTime()
          got += data.length
          percent = parseInt (got / length * 10).toFixed(0)
          progress = '##########'.substr(0,percent).green + '          '.substr(0,10-percent)
          speed = (got / (now - start) / 1024).toFixed(2) + ' mbps'
          line = '[' + 'dl'.yellow + '] ' + 'node-webkit '.blue + '[ ' + progress + ' ] '
          if (line isnt oldline) or (now - last > 0.1)
            last = now
            @log line + ' @ ' + speed
            oldline = line
          out.write data
        res.on 'error', ->
          @log 'error downloading'.red, url
          process.exit 1
        res.on 'end', me.proceed
    install : -> new Xcript @, """
        cd #{DOTDIR} || exit 1
        rm -rf node-webkit
        tar xzvf node-webkit.tar.gz
        mv node-webkit-v0.7.5-#{os.type}-#{os.arch} node-webkit
        echo ok
      """, title : 'installing', subject : 'node-webkit', end : me.proceed
    linux_workaround : -> new Xcript @, """
      f="/lib/x86_64-linux-gnu/libudev.so.1"
      test -f  "$f" && {
        ln -sf "$f" #{DOTDIR}/node-webkit/libudev.so.0 && echo ok || echo failed
      } || echo 'n/a'
      """, title : 'workaround', subject : 'node-webkit', end : me.proceed
    done : callback

_otr_init = (callback) -> new Xync
  title : 'otr'
  start : ->
    api.emit 'init.otr'
    api.User = User = new OTR.User
      user : Settings.onion
      keys : "#{DOTDIR}/otr.keys"      # path to OTR keys file (required)
      fingerprints: "#{DOTDIR}/otr.fp" # path to fingerprints file (required)
      instags: "#{DOTDIR}/otr.instags" # path to instance tags file (required)
    if User.accounts().length < 1
      i = 0
      o = [ '/', '-', '\\', '-' ]
      u = => @log "Generating privatekey " + o[i++%o.length].yellow
      t = setInterval u, 1000
      User.generateKey Settings.onion , "irac", (err) =>
        clearInterval t
        if err
          @log "Something went wrong!", err.message
          process.exit 1
        else
          @log "Generated privatekey successfully"
          User.writeFingerprints()
          @proceed api.emit 'init.otr.done'
    else @proceed api.emit 'init.otr.done'
  done : callback

_rebuild_modules = (callback) ->
  build = (mod, done) ->
    path = require.resolve(mod).split('/'); path.pop(); path = path.join('/')
    sync.log path
    new Xcript sync, """
      cd #{DOTDIR} || exit 1
      mkdir -p ./nwmod
      cp -r "#{path}" ./nwmod
      cd ./nwmod/#{mod}
      nw-gyp rebuild --target=0.7.5
    """, title : 'rebuild', subject : mod, end : done
  sync = new Xync
    title : 'rebuild'.blue
    fork : yes
    buffertools : -> build 'buffertools', @proceed
    otr4 : -> build 'otr4', callback

_ssl_init = (callback) -> new Xync
  title : 'ssl'
  fork : yes
  key : ->
    Settings.ssl.cert = undefined
    new Xcript @, "openssl genrsa -out #{DOTDIR}/server-key.pem 4096",
      title : 'generate', subject : 'key', end : (status, err) =>
        @proceed Settings.ssl.key = fs.readFileSync(DOTDIR + "/server-key.pem", 'utf8')
  crt : -> if Settings.ssl.cert? then @proceed() else
    new Xcript @, """
      openssl req -new -x509 -subj "/C=XX/ST=irac/L=api/O=IT/CN=#{Settings.onion}" -key #{DOTDIR}/server-key.pem -out #{DOTDIR}/server-cert.pem
    """, title : 'generate', subject : 'key', end : (status,err) =>
      Settings.save Settings.ssl.cert = fs.readFileSync(DOTDIR + "/server-cert.pem", 'utf8')
      @proceed()
  done : callback

module.exports.init = init = (callback) ->
  Xhell.title = 'irac'.green
  sinit = new Xync
    title : 'init'.blue
    fork : yes
    config_dir : -> mkdir DOTDIR, (firstboot) =>
      if api.developer? then @log '[', 'bootstrapping'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow,
        os.type[if os.type is 'linux' then 'green' else 'red'] + '[' + os.arch.grey + ']'
        @log 'sudo apt-get install opus-tools build-essential make awk g++ nodejs nodejs-dev libotr5 libotr5-dev'.red
      if (@firstboot = firstboot) is true or api.init.force?
        @log 'firstboot'.blue
        Settings.read => Tor.genkeys =>
          Settings.ssl = {} unless Settings.ssl?
          j = new Xoin true
          j.part -> Tor.start j.join
          j.part -> mkdir DOTDIR + '/tmp', j.join
          j.part -> _otr_init j.join
          unless Settings.ssl.key? and Settings.ssl.cert?
            j.part -> _ssl_init j.join
          if api.init.developer?
            j.part -> _install_nodewebkit j.join
            j.part -> _rebuild_modules j.join
          j.end =>
            @log 'join-end'.red, j.count
            Settings.save @proceed
      else Settings.read => _otr_init => Tor.start @proceed
    settings : ->
      IRAC.handshake = IRAC.message(IRAC.ini, null, msg = Settings.name + ':' + Settings.onion + ':' + Settings.port)
      @proceed()
    ready : ->
      @log 'init:done'.green
      api.emit 'init.readconf'
      callback() if callback?

module.exports.devinit = devinit = (callback) ->
  api.init.developer = true
  api.init callback

module.exports.devgui = devgui = -> new Xync
  title : 'gui'
  fork : yes
  env : -> if fs.existsSync "#{DOTDIR}/node-webkit" then @proceed() else devinit @proceed
  launch : ->
    @log '[', 'starting'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow, DOTDIR
    args = ''; for k,v of optimist.argv
      continue if k is '$0' or k is '_'
      args += """ --#{k}='#{v}'"""
    new Xcript @, """
      cd "#{require('path').dirname __dirname}"
      LD_LIBRARY_PATH=#{DOTDIR}/node-webkit:$LD_LIBRARY_PATH \\
        "#{DOTDIR}/node-webkit/nw" . #{args}""", title : 'gui', subject : 'nw', end : =>
      process.exit 0