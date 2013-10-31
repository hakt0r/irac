###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

  | A Declaration of the Independence of Cyberspace |

      by John Perry Barlow <barlow@eff.org>

  Governments of the Industrial World, you weary giants of flesh and steel, I come from Cyberspace, the new home of Mind. On behalf of the future, I ask you of the past to leave us alone. You are not welcome among us. You have no sovereignty where we gather.

  We have no elected government, nor are we likely to have one, so I address you with no greater authority than that with which liberty itself always speaks. I declare the global social space we are building to be naturally independent of the tyrannies you seek to impose on us. You have no moral right to rule us nor do you possess any methods of enforcement we have true reason to fear.

  Governments derive their just powers from the consent of the governed. You have neither solicited nor received ours. We did not invite you. You do not know us, nor do you know our world. Cyberspace does not lie within your borders. Do not think that you can build it, as though it were a public construction project. You cannot. It is an act of nature and it grows itself through our collective actions.

  You have not engaged in our great and gathering conversation, nor did you create the wealth of our marketplaces. You do not know our culture, our ethics, or the unwritten codes that already provide our society more order than could be obtained by any of your impositions.

  You claim there are problems among us that you need to solve. You use this claim as an excuse to invade our precincts. Many of these problems don't exist. Where there are real conflicts, where there are wrongs, we will identify them and address them by our means. We are forming our own Social Contract . This governance will arise according to the conditions of our world, not yours. Our world is different.

  Cyberspace consists of transactions, relationships, and thought itself, arrayed like a standing wave in the web of our communications. Ours is a world that is both everywhere and nowhere, but it is not where bodies live.

  We are creating a world that all may enter without privilege or prejudice accorded by race, economic power, military force, or station of birth.

  We are creating a world where anyone, anywhere may express his or her beliefs, no matter how singular, without fear of being coerced into silence or conformity.

  Your legal concepts of property, expression, identity, movement, and context do not apply to us. They are all based on matter, and there is no matter here.

  Our identities have no bodies, so, unlike you, we cannot obtain order by physical coercion. We believe that from ethics, enlightened self-interest, and the commonweal, our governance will emerge . Our identities may be distributed across many of your jurisdictions. The only law that all our constituent cultures would generally recognize is the Golden Rule. We hope we will be able to build our particular solutions on that basis. But we cannot accept the solutions you are attempting to impose.

  In the United States, you have today created a law, the Telecommunications Reform Act, which repudiates your own Constitution and insults the dreams of Jefferson, Washington, Mill, Madison, DeToqueville, and Brandeis. These dreams must now be born anew in us.

  You are terrified of your own children, since they are natives in a world where you will always be immigrants. Because you fear them, you entrust your bureaucracies with the parental responsibilities you are too cowardly to confront yourselves. In our world, all the sentiments and expressions of humanity, from the debasing to the angelic, are parts of a seamless whole, the global conversation of bits. We cannot separate the air that chokes from the air upon which wings beat.

  In China, Germany, France, Russia, Singapore, Italy and the United States, you are trying to ward off the virus of liberty by erecting guard posts at the frontiers of Cyberspace. These may keep out the contagion for a small time, but they will not work in a world that will soon be blanketed in bit-bearing media.

  Your increasingly obsolete information industries would perpetuate themselves by proposing laws, in America and elsewhere, that claim to own speech itself throughout the world. These laws would declare ideas to be another industrial product, no more noble than pig iron. In our world, whatever the human mind may create can be reproduced and distributed infinitely at no cost. The global conveyance of thought no longer requires your factories to accomplish.

  These increasingly hostile and colonial measures place us in the same position as those previous lovers of freedom and self-determination who had to reject the authorities of distant, uninformed powers. We must declare our virtual selves immune to your sovereignty, even as we continue to consent to your rule over our bodies. We will spread ourselves across the Planet so that no one can arrest our thoughts.

  We will create a civilization of the Mind in Cyberspace. May it be more humane and fair than the world your governments have made before.

  Davos, Switzerland
  February 8, 1996

###

_me = 'tor'.grey

ync = require 'ync' unless ync?
portfinder = require 'portfinder'

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
      share.pubkey = Tor.readKey name

  @start : (onready) -> startup = new ync.Sync
      fork : yes

      check_port : ->
        portfinder.basePort = 9050
        portfinder.getPort (err,port) ->
          if port isnt portfinder.basePort
            Tor.running = yes
            console.log _me, 'tor seems to be running'.yellow
            startup.run('ready')
          else startup.proceed Tor.port = port

      config_tor : ->
        share.dir = _base+'/'+name for name, share of @hiddenService
        console.log _me, 'update' + _base + '/torrc'
        fs.writeFile _base + '/torrc', Tor.makerc(), startup.proceed

      start_tor  : ->
        cmd = 'tor -f '+_base+'/torrc'
        console.log _me, 'running', cmd
        shell.readlines cmd,
          line : (line) ->
            console.log 'tor'.grey, line
            if r = line.match /Bootstrapped ([0-9]+)%/
              console.log line
            else if line.match /Tor has successfully opened a circuit/
              startup.proceed()

      ready : ->
        Tor.readConf()
        if onready?
          console.log _me, 'post-init'.green
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