###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ DOTDIR, cp, fs, Settings, xl, ync } = ( api = global.api )

portfinder = require 'portfinder'

module.exports.Tor = class Tor
  @running : no
  @readOnion : -> try fs.readFileSync(DOTDIR+'/hostname').toString('utf8').trim()
  @readKey : -> try fs.readFileSync(DOTDIR+'/private_key').toString('utf8').trim()

  @readConf : ->
    Settings.onion   = Tor.readOnion().replace /.onion$/, ''
    Settings.privkey = Tor.readKey()

  @start : (callback) -> startup = new ync.Sync
    fork : yes

    checkport : ->
      api.emit 'tor.checkport'
      portfinder.basePort = Settings.torport
      portfinder.getPort (err,port) ->
        if port isnt portfinder.basePort
          Tor.running = yes
          console.log 'tor'.grey, 'tor seems to be running'.yellow
          startup.run('ready')
        else startup.proceed()

    config : =>
      api.emit 'tor.updaterc'
      console.log 'tor'.grey, 'update' + DOTDIR + '/torrc'
      fs.writeFile DOTDIR + '/torrc', Tor.makerc(), startup.proceed

    start  : ->
      api.emit 'tor.start'
      cmd = 'tor -f '+DOTDIR+'/torrc --pidfile "' + DOTDIR + '/tor/tor.pid"'
      console.log 'tor'.grey, 'running', cmd
      Tor.instance = xl.scriptline cmd,
        line : (line) ->
          line = line.trim()
          api.emit 'tor.log', line unless line is ''
          startup.proceed() if line.match /Tor has successfully opened a circuit/

    ready : ->
      console.log 'tor'.grey, 'ready'
      Tor.readConf()
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