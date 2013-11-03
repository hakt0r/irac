###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ cp, fs, Settings, Kreem } = global

portfinder = require 'portfinder'
module.exports = class Tor
  @running : no
  @readOnion : -> try fs.readFileSync(_base+'/hostname').toString('utf8').trim()
  @readKey   : -> try fs.readFileSync(_base+'/private_key').toString('utf8').trim()

  @readConf : ->
    Settings.onion   = Tor.readOnion().replace /.onion$/, ''
    Settings.privkey = Tor.readKey()

  @start : (callback) -> startup = new ync.Sync
      fork : yes

      checkport : ->
        Kreem.emit 'tor.checkport'
        portfinder.basePort = Settings.torport
        portfinder.getPort (err,port) ->
          if port isnt portfinder.basePort
            Tor.running = yes
            console.log 'tor'.grey, 'tor seems to be running'.yellow
            startup.run('ready')
          else startup.proceed()

      config : =>
        Kreem.emit 'tor.updaterc'
        console.log 'tor'.grey, 'update' + _base + '/torrc'
        fs.writeFile _base + '/torrc', Tor.makerc(), startup.proceed

      start  : ->
        Kreem.emit 'tor.start'
        cmd = 'tor -f '+_base+'/torrc --pidfile "' + _base + '/tor/tor.pid"'
        console.log 'tor'.grey, 'running', cmd
        shell.readlines cmd,
          line : (line) ->
            Kreem.emit 'tor.log', line
            startup.proceed() if line.match /Tor has successfully opened a circuit/

      ready : ->
        Tor.readConf()
        callback() if callback?
        Kreem.emit 'tor.ready'

  @makerc : -> """
      DataDirectory #{_base}/tor
      SocksPort #{Settings.torport}
      HiddenServiceDir  #{_base}
      HiddenServicePort #{Settings.port} 127.0.0.1:#{Settings.port}
    """