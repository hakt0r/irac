###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

cp       = require 'child_process'
sudo     = require 'sudo'
net      = require 'net'
util     = require 'util'
colors   = require 'colors'

__env = process.env
__env.LANG = 'C'

class Ultrashell
  old_key  : null
  old_mode : 'log'
  linebuffer : ''
  print : (args...) =>
    @linebuffer += args.join ''
    util.print.apply null, args
  back : (howmany=1)=>
    @linebuffer = @linebuffer.substr(0,-1)
    util.print "\x1b[#{howmany}D"
  reset  : =>
    @linebuffer = ''; util.print "\x1b[0E\x1b[0J";
  clear  : =>
    @linebuffer = ''; util.print "\x1b[2J";
  commit : =>
    @linebuffer = ''; util.print '\n'
  log : =>
    util.print  "\x1b[0E\x1b[0J";
    console.log.apply null, arguments
    util.print  @linebuffer

class Shellglyph
  constructor : (@glyph) ->
    @glyph = [ '|'.yellow, '/'.green, '-'.yellow, '\\'.green ] unless @glyph?
    @index = @glyph.length - 1
  last  :     => @glyph[@index]
  next  :     => @glyph[(@index = (@index + 1) % (@glyph.length))]
  show  : (i) => @glyph[(i % (@glyph.length))]

module.exports = Lib = 

  Shellglyph : Shellglyph
  Ultrashell : Ultrashell

  sh : (cmd,args,callback) ->
    c = cp.spawn cmd, args, {encoding:'utf8'}
    c.on 'exit', callback

  script : (cmd,callback) ->
    c = cp.spawn "sh", ["-c",cmd]
    c.stdout.setEncoding 'utf8'
    c.stderr.setEncoding 'utf8'
    if callback?
      c.buf = []
      c.stdout.on 'data', (d) -> c.buf.push(d)
      c.stderr.on 'data', (d) -> c.buf.push(d)
      c.on 'close', (e) -> callback(e, c.buf.join().trim())
    else
      c.stdout.on 'data', (d) -> console.log d
      c.stderr.on 'data', (d) -> console.log d

  scriptline : (cmd,callback) ->
    c = cp.spawn "sh", [ "-c", cmd ]
    c.stdout.setEncoding 'utf8'
    c.stderr.setEncoding 'utf8'
    callback.error = console.log unless callback.error
    callback.line  = console.log unless callback.line
    callback.end   = (->) unless callback.end
    c.stderr.on 'data', (data) -> callback.error l.trim() for l in data.split '\n'
    c.stdout.on 'data', (data) -> callback.line  l.trim() for l in data.split '\n'
    c.on 'close', callback.end

  readlines : (cmd,opts) ->
    c = cp.spawn "sh", ["-c", cmd]
    c.stdout.setEncoding 'utf8'
    c.stderr.setEncoding 'utf8'
    if opts.end  then c.on       'close', (e) -> opts.end     e
    if opts.line then c.stdout.on 'data', (d) ->
      d = d.split /\n/g ; d.pop() ; for line in d
        opts.line line
    if opts.error then c.stderr.on 'data', (d) ->
      d = d.split /\n/g ; d.pop() ; for line in d
        opts.error line

  waitproc : (opts={}) ->
    start = Date.now()/1000 # util.print "wait ".yellow + " for ".white + opts.name + ' '
    wait = setInterval ( ->
      Lib.running opts.name, (e) ->
        unless e
          clearInterval wait
          opts.done true
        else
          clearInterval wait
          opts.done false if Date.now() / 1000 - start > opts.timeout
          util.print "."
    ), 250

  running : (name, callback) ->
    Lib.script "busybox ps -o comm | grep '^#{name}'", callback

  killall : (name, callback, fail) -> # util.print "kill".yellow + ' ' + name + ' '
    Lib.sh "busybox",["killall","-9",name], (e) ->
      Lib.running name, (e) ->
        unless e # console.log  "failed".green
          fail() if fail?
        else # console.log  "done".green
          callback() if callback?

  forkdm : (args,callback) -> 
    cmd = args.shift()
    cp.spawn cmd, args, detached : yes
    Lib.waitproc name : cmd, timeout : 5, done : callback

  readproc : (opts) ->
    { cmd, args } = opts
    handler = {}
    for t in ['exit','err','out','error'] when opts[t]?
      handler[t] = opts[t]; delete opts[t]
    if opts.script?
      s = opts.script; delete opts['script']
      cmd = 'sh'; args = ['-c',s]
    if opts.sudo?
      s = opts.sudo; delete opts['sudo']
      p = sudo [cmd].concat(args), cachePassword : yes, spawnOptions : env : __env
    else p = cp.spawn cmd, args, env : __env
    for t in ['out','err'] when handler[t]?
      p['std'+t].setEncoding 'utf8'
      p['std'+t].on 'data', handler[t]
    if handler.error?
      error = false; _err = (e) -> error = yes; handler.error e
      p.on 'error', _err; p.stderr.on 'data', _err
      p.on 'exit', (status) -> handler.exit(status) unless error
    else if handler.exit? then p.on 'exit', handler.exit
    return p

  elevate : (cmd,done) ->
    x = typeof cmd is 'function'
    done = cmd if x
    cmd  = ["echo","ok"] if not cmd? or x
    done = (->) unless done?
    e = sudo cmd, cachePassword : yes, spawnOptions : silent : yes
    e.on 'exit', done