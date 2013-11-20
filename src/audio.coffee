###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ DOTDIR, cp, fs, EventEmitter } = ( api = global.api )

class HackyPlayer extends EventEmitter
  queue : {}
  playing : no
  play : (item) =>
    item.decoder = create item.mime
    return unless item.decoder?
    @playing = yes
    read = fs.createReadStream item.path, start : item.offset
    console.log 'playing'.red + ' ' + item.path if item.offset is 0 
    read.on 'data', (data) ->
      item.offset += data.length
      item.decoder.stdin.write data
    read.on 'end', (status,error) =>
      @playing = no
      item.buffer = 0
  create : (mime) => switch mime
    when 'audio/opus'
      cp.spawn('padsp',['opusdec','-'],stdio:['pipe','ignore','ignore'])
    else undefined

class HackyRecorder extends EventEmitter
  running : no
  toggle : => if @running then @stop() else @start()
  start  : =>
    return if @running
    feed = api.IRAC.announce 'audio/opus'
    @record = cp.spawn 'arecord',['-c','1','-r','48000','-twav','-'],stdio:['pipe','pipe','ignore']
    encode  = cp.spawn 'opusenc',['--ignorelength','--bitrate','96','-','-'],stdio:['pipe','pipe','ignore']
    @record.stdout.pipe encode.stdin
    encode.stdout.on 'data', feed
    @running = yes
    @emit 'start'
  stop : =>
    return unless @running
    @running = no
    @record.kill('SIGQUIT')
    @emit 'stop'

module.exports =
  Recorder : new HackyRecorder
  Player : new HackyPlayer
