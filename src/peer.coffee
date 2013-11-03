###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

module.exports = class Peer
  @byId      : {}
  @lastid    : 0
  @broadcast : (data) => socket.write data for id, socket of @byId
  @handshake : (peer) => peer.write "IRAC kreem/0.9 PEER " + Settings.onion + "\r\n"
  @peerMessage : (peer) =>
    buffer    = ''
    info      = peer.info
    binary    = no
    frameSize = 0
    streamId  = null
    return (msg) =>
      buffer += msg 
      while true
        if binary 
          break unless buffer.length > frameSize
          binary = no
          msg    = buffer.substr 0, frameSize
          buffer = buffer.substr frameSize
          Player.frame streamId, new Buffer(msg,'base64')
        else if ( msgEnd = buffer.indexOf('\r\n') ) > -1
          type   = buffer.substr(0, 4)
          msg    = buffer.substr(5, msgEnd).split ' '
          buffer = buffer.substr msgEnd + 2
          switch type
            when 'IRAC'
              info.version = msg.shift()
              info.class   = msg.shift()
              info.socket  = peer
              kreem.emit 'connection', info
            when 'MESG'
              Player.create info.name + parseInt(msg[0]), msg[1]
            when 'FRME'
              binary = yes
              streamId   = info.name + parseInt msg[0]
              frameSize  = parseInt msg[1]
              continue
        else break