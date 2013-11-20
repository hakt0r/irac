###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

###
  The Mighty init sync
###

{ Tor, Player, Recorder, EventEmitter, ync, DOTDIR, fs,
  Settings, sha512, md5, mkdir, xl, cp, OTR, IRAC,
} = ( api = global.api )

module.exports.init = init = (callback) -> new ync.Sync
  debug : yes

  config_dir : -> mkdir DOTDIR, (firstboot) => @firstboot = firstboot; @proceed()

  read_settings : -> Settings.read @proceed
  # config_dir_setup : -> unless @firstboot and api.GUI then @proceed() else api.emit 'init.firstboot', @proceed 

  apply_settings : ->
    IRAC.handshake = IRAC.message(IRAC.ini, null, msg = Settings.name + ':' + Settings.onion + ':' + Settings.port)
    console.log '[' + msg.red + ']'
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
          xl.script "openssl genrsa -out #{DOTDIR}/server-key.pem 4096", (status,err) ->
            console.log status + err
            ssl.proceed Settings.ssl.key = fs.readFileSync DOTDIR + "/server-key.pem", 'utf8'

        generate_crt : -> if Settings.ssl.cert? then ssl.proceed() else
          console.log 'Generating ssl cert: '.red + DOTDIR.yellow
          xl.script """
            openssl req -new -x509 -subj "/C=XX/ST=irac/L=api/O=IT/CN=#{Settings.onion}" -key #{DOTDIR}/server-key.pem -out #{DOTDIR}/server-cert.pem
          """, =>
            ssl.proceed Settings.ssl.cert = fs.readFileSync DOTDIR + "/server-cert.pem", 'utf8'
            Settings.save()

        done : -> j.join console.log 'ssl keyread done'

    j.part() ## load otr private key / initialize account
    api.emit 'init.otr'
    api.User = User = new OTR.User
      user : Settings.onion
      keys : "#{DOTDIR}/otr.keys"      # path to OTR keys file (required)
      fingerprints: "#{DOTDIR}/otr.fp" # path to fingerprints file (required)
      instags: "#{DOTDIR}/otr.instags" # path to instance tags file (required)
    if User.accounts().length < 1
      console.log "OTR".yellow, "Generating Key"
      User.generateKey Settings.onion , "irac", (err) ->
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

module.exports.devinit = devinit = -> api.init ->
  console.log '[', 'boostrapping'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow,
    os.type[if os.type is 'linux' then 'green' else 'red'] + '[' + os.arch.grey + ']'
  url = "https://s3.amazonaws.com/node-webkit/v0.7.5/node-webkit-v0.7.5-#{os.type}-#{os.arch}.tar.gz"
  boostrap = new ync.Sync
    title : 'boostrap    '

    download_webkit : -> get = require('https').get url, (res) ->
      oldline = ''
      start = (new Date).getTime()
      length = parseInt res.headers['content-length']
      got = 0
      out = fs.createWriteStream(DOTDIR + '/node-webkit.tar.gz')
      res.on 'data', (data) ->
        now = (new Date).getTime()
        got += data.length
        percent = parseInt (got / length * 10).toFixed(0)
        progress = '##########'.substr(0,percent).green + '          '.substr(0,10-percent)
        speed = (got / (now - start) / 1024).toFixed(2) + ' mbps'
        line = '[ ' + 'downloading  '.yellow + '] ' + 'node-webkit '.blue + '[ ' + progress + ' ] '
        if (line isnt oldline) or (now - last > 0.5)
          last = now
          Xhell.reset()
          Xhell.print line + ' @ ' + speed
          oldline = line
        out.write data
      res.on 'error', ->
        console.log 'error downloading'.red, url
        process.exit 1
      res.on 'end', -> boostrap.proceed Xhell.commit()

    install_webkit : -> new CLScript """
        cd #{DOTDIR} || exit 1
        rm -rf node-webkit
        tar xzvf node-webkit.tar.gz
        mv node-webkit-v0.7.5-#{os.type}-#{os.arch} node-webkit
        echo ok
      """, title : 'installing  ', subject : 'node-webkit', end : boostrap.proceed

    webkit_linux_workaround : -> new CLScript """
      f="/lib/x86_64-linux-gnu/libudev.so.1"
      test -f  "$f" && {
        ln -sf "$f" #{DOTDIR}/node-webkit/libudev.so.0 && echo ok || echo failed
      } || echo 'n/a'
      """, title : 'workaround  ', subject : 'node-webkit', end : boostrap.proceed

    install_nwgyp : -> new CLScript """
        sudo npm install -g nw-gyp
        echo ok
      """, title : 'installing  ', subject : 'nwgyp', end : boostrap.proceed

    install_devtools : -> new CLScript """
        sudo apt-get install opus-tools build-essential make awk g++ nodejs nodejs-dev libotr5 libotr5-dev
        echo ok
      """, title : 'installing  ', subject : 'opus, devtools', end : boostrap.proceed

    rebuild_buffertools : ->
      path = require.resolve('buffertools').split '/'
      path.pop()
      path = path.join '/'
      new CLScript """
        cd #{DOTDIR} || exit 1
        cp -r "#{path}" ./node-webkit
        cd ./node-webkit/buffertools
        nw-gyp rebuild --target=0.7.5
        echo ok
      """, title : 'rebuilding  ', subject : 'buffertools', end : boostrap.proceed

    rebuild_otr4 : ->
      path = require.resolve('otr4').split '/'
      path.pop()
      path = path.join '/'
      new CLScript """
        cd #{DOTDIR} || exit 1
        cp -r "#{path}" ./node-webkit
        cd ./node-webkit/otr4
        nw-gyp rebuild --target=0.7.5
        echo ok
      """, title : 'rebuilding  ', subject : 'otr4', end : boostrap.proceed

    done : -> process.exit 0

module.exports.devgui = devgui = ->
  console.log '[', 'starting'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow, DOTDIR
  args = ''; for k,v of optimist.argv
    continue if k is '$0' or k is '_'
    args += """ --#{k}='#{v}'"""
  console.log args
  xl.script """
    cd "#{require('path').dirname __dirname}"
    LD_LIBRARY_PATH=#{DOTDIR}/node-webkit:$LD_LIBRARY_PATH \\
      "#{DOTDIR}/node-webkit/nw" . #{args}
  """