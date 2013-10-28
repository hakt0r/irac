_me = 'tor'.grey

portfinder = require 'portfinder'

progress = new shell.Shellglyph [
  '@'.red, '|'.red, '/'.red,
  '-'.yellow, '\\'.yellow, '-'.yellow,
  '\\'.green, '-'.green, '/'.green,
  '@'.green, '[' + 'tor'.green + ']' ]

module.exports = class Tor
  @running : no
  @port    : 9050

  @hiddenService :
    ssh   : { port : 22 }
    http  : { port : 80 }
    devel : { port : 8080 }
    kreem : { port : 33023 }

  @readOnion : (name) -> fs.readFileSync(_base+'/'+name+'/hostname').toString('utf8').trim()
  @readKey   : (name) -> fs.readFileSync(process.env.HOME+'/.ssh/id_rsa.pub').toString('utf8').trim().split(' ')[1]

  @readConf : -> for name, share of @hiddenService
    try
      share.onion  = r = Tor.readOnion name
      share.pubkey = Tor.readKey   name
      # ultra.log _me, 'hidden'.red, name, share.port, r.yellow

  @start : (onready) -> startup = new ync.Sync
      fork : yes

      check_port : ->
        portfinder.basePort = 9050
        portfinder.getPort (err,port) ->
          if port isnt portfinder.basePort
            Tor.running = yes
            ultra.log _me, 'tor seems to be running'.yellow
            startup.run('ready')
          else startup.proceed Tor.port = port

      config_tor : ->
        share.dir = _base+'/'+name for name, share of @hiddenService
        ultra.log _me, 'update' + _base + '/torrc'
        fs.writeFile _base + '/torrc', Tor.makerc(), startup.proceed

      start_tor  : ->
        cmd = 'tor -f '+_base+'/torrc'
        ultra.log _me, 'running', cmd
        i = 0; ultra.print _me, '['+cmd.red+']'
        shell.readlines cmd,
          line : (line) ->
            ultra.log 'tor'.grey, line
            if r = line.match /Bootstrapped ([0-9]+)%/
              ultra.reset()
              ultra.print _me, ' ', progress.show((r[1]/10).toFixed 0)
            else if line.match /Tor has successfully opened a circuit/
              startup.proceed()

      ready : ->
        Tor.readConf()
        if onready?
          ultra.reset()
          ultra.log _me, 'post-init'.green
          onready()

  @makerc : ->
    hiddenService = 
      if @hiddenService?
        list = for name, service of @hiddenService
          { address, pubport, port } = service
          address = '127.0.0.1'
          pubport = port unless pubport?
          dir = _base + '/' + name
          """
          HiddenServiceDir #{dir}
          HiddenServicePort #{pubport} #{address}:#{port}
          """
        list.join '\n'
      else ''

    r = """
      SocksPort #{Tor.port} # Default: localhost:9050
      #{hiddenService}
      #SocksPort 192.168.0.1:9100 # Bind to this adddress:port too.
      #SocksPolicy accept 192.168.0.0/16
      #SocksPolicy reject *
      #Log notice file /var/log/tor/notices.log
      #Log debug file /var/log/tor/debug.log
      #Log notice syslog
      #Log debug stderr
      #RunAsDaemon 1
      #DataDirectory /var/lib/tor
      #ControlPort 9051
      #HashedControlPassword 16:872860B76453A77D60CA2BB8C1A7042072093276A3D701AD684053EC4C
      #CookieAuthentication 1
      #ORPort 9001
      #ORPort 443 NoListen
      #ORPort 127.0.0.1:9090 NoAdvertise
      #Address noname.example.com
      # OutboundBindAddress 10.0.0.5
      #Nickname ididnteditheconfig
      #RelayBandwidthRate 100 KB  # Throttle traffic to 100KB/s (800Kbps)
      #RelayBandwidthBurst 200 KB # But allow bursts up to 200KB/s (1600Kbps)
      #AccountingMax 4 GB
      #AccountingStart day 00:00
      #AccountingStart month 3 15:00
      #ContactInfo Random Person <nobody AT example dot com>
      #ContactInfo 0xFFFFFFFF Random Person <nobody AT example dot com>
      #DirPort 9030 # what port to advertise for directory connections
      #DirPort 80 NoListen
      #DirPort 127.0.0.1:9091 NoAdvertise
      #DirPortFrontPage /etc/tor/tor-exit-notice.html
      #MyFamily $keyid,$keyid,...
      #ExitPolicy accept *:6660-6667,reject *:* # allow irc ports but no more
      #ExitPolicy accept *:119 # accept nntp as well as default exit policy
      #ExitPolicy reject *:* # no exits allowed
      #BridgeRelay 1
      #PublishServerDescriptor 0
    """