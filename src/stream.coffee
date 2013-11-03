###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

module.exports = class Stream
  @id : 0
  constructor : (@opts={}) ->
    @opts.group = Peer.byId unless @opts.group?
    @id = Stream.id++
    @cast "MESG #{@id} #{@opts.mime}\r\n"
  cast : (data) => socket.write data for id, socket of @opts.group
  feed : (data) =>
    data = data.toString 'base64'
    @cast 'FRME ' + @id + ' ' + data.length + '\r\n'
    @cast data
