###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ DOTDIR, cp, fs, Settings, path, ync } = ( api = global.api )

module.exports = Tor : class Tor

  @stop : (callback) =>
    @instance.kill() if @instance?
    callback() if callback?

  @init : (callback, onconfig) =>
    api.on   'tor.ready',  callback if callback?
    api.on   'tor.config', onconfig if onconfig?
    api.emit 'tor.start'
    rcfile  = DOTDIR + path.sep + 'torrc'
    pidfile = DOTDIR + path.sep + 'tor' + path.sep + 'tor.pid'
    s = new ync.Sync

      portfinder : =>
        portfinder = require 'portfinder'
        portfinder.basePort = Math.floor 1024 + Math.random()*10000
        portfinder.getPort (err,@port) =>
          api.emit 'tor.port', @port
          s.proceed()

      torrc : =>
        api.emit 'tor.genconfig'
        fs.writeFile rcfile, """
          SocksPort #{@port}
          DataDirectory #{DOTDIR}/tor
          HiddenServiceDir #{DOTDIR}
          HiddenServicePort #{Settings.port} 127.0.0.1:#{Settings.port}
          """, s.proceed

      kill  : ->
        if fs.existsSync pidfile
          pid = parseInt fs.readFileSync(pidfile,'utf8')
          cp.spawn('kill',[pid]).on('close',s.proceed)
        else s.proceed()

      spawn : =>
        _log = (line) -> api.emit 'tor.log', line
        _ready = (line) -> if line.match /Tor has successfully opened a circuit/
          cli[pipe].removeListener 'data', _ready for pipe in ['stdout','stderr']
          api.emit 'tor.ready'
        _config = (line) => if line.match /microdescriptor cache/
          cli[pipe].removeListener 'data', _config for pipe in ['stdout','stderr']
          @key   = fs.readFileSync(DOTDIR + path.sep + 'private_key','utf8').trim()
          @onion = fs.readFileSync(DOTDIR + path.sep + 'hostname','utf8').trim()
          # api.emit 'tor.config'
          return @instance.kill() if onconfig? and onconfig @ is true
        @instance = cli = cp.spawn 'tor', [ '-f', rcfile ,'--pidfile', pidfile ]
        for pipe in ['stdout','stderr']
          for fnc in [_log,_config,_ready]
            cli[pipe].setEncoding 'utf8'; cli[pipe].on 'data', fnc
