###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ DOTDIR, cp, fs, Settings, xl, ync, Xync, Xcript } = ( api = global.api )

portfinder = require 'portfinder'

module.exports.Tor = class Tor
  @running : no
  @readOnion : -> try fs.readFileSync(DOTDIR+'/hostname').toString('utf8').trim()
  @readKey : -> try fs.readFileSync(DOTDIR+'/private_key').toString('utf8').trim()

  @readConf : ->
    Settings.onion   = Tor.readOnion().replace /.onion$/, ''
    Settings.privkey = Tor.readKey()

  @genkeys : (callback) ->
    cmd = 'tor -f '+DOTDIR+'/torrc --pidfile "' + DOTDIR + '/tor/tor.pid"'
    new Xync
      title : 'keygen'
      fork : yes
      checkport : ->
        portfinder.basePort = Settings.torport
        portfinder.getPort (err,port) =>
          if port isnt portfinder.basePort
            Tor.running = yes
            console.log 'tor'.grey, 'tor seems to be running'.yellow
            @run 'done'
          else @proceed()
      config : -> fs.writeFile DOTDIR + '/torrc', Tor.makerc(), @proceed
      start : -> Tor.instance = xl.scriptline cmd, line : (line) =>
        @log line
        @proceed() if line.trim().match /microdescriptor/
      done : ->
        Tor.readConf()
        Tor.instance.kill()
        callback() if callback?

  @start : (callback) -> new Xync
    title : 'tor'
    checkport : ->
      api.emit 'tor.checkport', Settings.torport
      portfinder.basePort = Settings.torport
      portfinder.getPort (err,port) =>
        if port isnt portfinder.basePort
          Tor.running = yes
          @log 'tor seems to be running'.yellow
          @run('ready')
        else @proceed()
    config : ->
      api.emit 'tor.updaterc'
      @log 'tor'.grey, 'update' + DOTDIR + '/torrc'
      fs.writeFile DOTDIR + '/torrc', Tor.makerc(), @proceed
    start  : (err) ->
      @log err
      api.emit 'tor.start'
      cmd = 'tor -f '+DOTDIR+'/torrc --pidfile "' + DOTDIR + '/tor/tor.pid"'
      @log 'running', cmd
      Tor.instance = xl.scriptline cmd,
        line : (line) =>
          line = line.trim()
          api.emit 'tor.log', line unless line is ''
          @log line
          @proceed() if line.match /Tor has successfully opened a circuit/
    ready : ->
      Tor.readConf()
      @log 'ready'.green
      api.emit 'tor.ready'
      callback() if callback?

  @stop : (callback) =>
    @instance.kill() if @instance?
    callback if callback?

  @makerc : -> """
      DataDirectory #{DOTDIR}/tor
      SocksPort #{Settings.torport}
      HiddenServiceDir  #{DOTDIR}
      HiddenServicePort #{Settings.port} 127.0.0.1:#{Settings.port}
    """