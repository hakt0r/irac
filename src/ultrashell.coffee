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