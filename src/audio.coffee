###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

cp = global.cp
EventEmitter = global.EventEmitter

class HackyPlayer extends EventEmitter
  stream : {}
  playing : no
  play : (item) =>
    @playing = yes
    read = fs.createReadStream item.path, start : item.offset
    console.log 'playing'.red + ' ' + item.path if item.offset is 0 
    read.on 'data', (data) ->
      item.offset += data.length
      item.decoder.stdin.write data
    read.on 'end', (status,error) =>
      @playing = no
      item.buffer = 0
  create : (id, mime) =>
    console.log 'new_stream', id
    p = _base + '/tmp/' + id
    w = fs.createWriteStream p
    @stream[id] = s =
      id:id
      path:p
      file:w
      buffer:0
      offset:0
      decoder:cp.spawn('padsp',['opusdec','-'],stdio:['pipe','ignore','ignore'])
  frame : (id, msg) =>
    (s = @stream[id]).file.write msg
    @play s unless @playing

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
    @record.kill('SIGTERM')
    @emit 'stop'

module.exports =
  Recorder : new HackyRecorder
  Player   : new HackyPlayer
