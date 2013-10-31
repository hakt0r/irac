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

global.EventEmitter = EventEmitter = require('events').EventEmitter

Settings = global.Settings
sha512   = global.sha512

class Peer
  @byId : {}
  @lastid : 0

  @broadcast : (data) => socket.write data for id, socket of @byId
  @handshake : (peer) -> peer.write "IRAC kreem/0.9 PEER " + Settings.name + ' ' + Settings.pubkey + "\r\n"

  @handlePeerMessage : (peer,info) =>
    buffer    = new Buffer ''
    binary    = no
    frameSize = 0
    stream    = {}
    return (msg) =>
      buffer = Buffer.concat [buffer, msg]
      while true
        if binary 
          if buffer.length > frameSize
            binary = no
            msg    = buffer.slice 0, frameSize
            buffer = buffer.slice frameSize
            Player.frame stream[streamId], msg
            console.log 'binary'.green, frameSize, msg.length
          else break
        else if ( msgEnd = buffer.indexOf('\r\n') ) > -1
          type   = buffer.toString('utf8', 0, 4)
          msg    = buffer.toString('utf8', 5, msgEnd).split ' '
          buffer = buffer.slice msgEnd + 2
          console.log 'ascii'.red, type, msg.length, msg
          switch type
            when 'IRAC'
              info.version = msg.shift()
              info.class   = msg.shift()
              info.user    = msg.shift()
              info.pubkey  = msg.join ' '
              info.socket  = peer
              kreem.emit 'connection', info
            when 'MESG'
              id   = parseInt msg[0]
              mime = msg[1]
              if mime is 'audio/opus'
                stream[id] = id : id, mime : msg[1], socket : peer
            when 'FRME'
              binary = yes
              streamId   = parseInt msg[0]
              frameSize  = parseInt msg[1]
              continue
        else break

class Stream
  @id : 0
  constructor : (@opts={}) ->
    @opts.group = Peer.byId unless @opts.group?
    @id = Stream.id++
    @cast "MESG #{@id} #{@opts.mime}\r\n"
  cast : (data) => socket.write data for id, socket of @opts.group
  feed : (data) =>
    @cast 'FRME ' + @id + ' ' + data.length + '\r\n'
    @cast data

###
  "audio"
###

cp = require 'child_process'

class HackyPlayer extends EventEmitter
  constructor : ->
    @decoder = cp.spawn 'padsp',['opusdec','-'],stdio:['pipe','ignore','ignore']
    @decoder.on 'end', (error) -> console.log 'decoder'.red, error
  frame : (stream, msg) =>
    @decoder.stdin.write msg

class HackyRecorder extends EventEmitter
  running : no
  toggle : => if @running then @stop() else @start()
  start  : =>
    return if @running
    @running = yes
    stream = new Stream mime : 'audio/opus'
    @record = cp.spawn 'arecord',['-c','1','-r','48000','-twav','-'],stdio:['pipe','pipe','ignore']
    encode  = cp.spawn 'opusenc',['--ignorelength','--bitrate','96','-','-'],stdio:['pipe','pipe','ignore']
    @record.stdout.pipe encode.stdin
    encode.stdout.on 'data', stream.feed
    @emit 'start'
  stop : =>
    return unless @running
    @running = no
    @record.kill('SIGKILL')
    @emit 'stop'

Recorder = new HackyRecorder
Player   = new HackyPlayer

###
  Network Implementation
###

SocksFactory = require "socks-factory"

connect = (host='127.0.0.1',port=33023) ->
  id = Peer.lastid++
  nfo = id : id, user : 'anonyomus', onion : host, port : port
  if host.indexOf(':') > 0
    [ host, port ] = host.split ':'
    port = parseInt port
  options =
    proxy:  ipaddress: "127.0.0.1", port: 9050, type: 5
    target: host: host, port: port
    command: "connect"
  SocksFactory.createConnection options, (err, socket, info) ->
    unless err
      Peer.handshake socket
      socket.on "data", Peer.handlePeerMessage(socket, nfo)
      socket.on "error", console.log
      socket.resume()
    else console.log host, err

listen = (opts) ->
  { addr, port, nick, pubkey } = opts
  Peer.nick = nick
  Peer.pubky = pubkey
  router = require("net").createServer (socket) ->
    id = Peer.lastid++
    info = id : id, user : 'anonyomus'
    socket.on "data", Peer.handlePeerMessage(socket,info)
    socket.on "end", ->
      console.log "@" + info.user + " disconnected from " + socket.remoteAddress
      socket.end()
      delete Peer.byId[id]
      kreem.emit 'disconnected', info
    socket.on "timeout", ->
      console.log "@" + info.user + " timeout from " + socket.remoteAddress
      socket.end()
      delete Peer.byId[id]
      kreem.emit 'timeout', info
    Peer.byId[id] = socket
    Peer.handshake socket

  router.listen port, addr

  console.log [(s = Tor.hiddenService['kreem']).onion, s.pubkey ].join '\n'

  setTimeout ( -> connect 'jt6jfstgkbbahnhe.onion' ), 3000

kreem = new EventEmitter
kreem.Player = Player
kreem.Recorder = Recorder
kreem.Stream = Stream
kreem.Peer = Peer
kreem.connect = connect
kreem.listen = listen

module.exports = kreem