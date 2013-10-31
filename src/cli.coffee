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

global.GUI = false

require './common'

_me  = 'cli'.blue
os = require 'os'
arch = os.arch().toLowerCase()
type = os.type().toLowerCase()

class CLSync extends ync.Sync
  constructor : (opts) ->
    [ _run, _exec ] = [ @run, @exec ]
    _widget = (fnc) => =>
      @widget(); fnc.apply @, arguments
    @run  = _widget _run
    @exec = _widget _exec
    super opts
  widget : =>
    console.log '[ ' + @title.yellow + ' ] ' + @current.yellow

class CLScript
  constructor : (cmd,opts={}) ->
    { @end, @title, @subject } = opts
    @subject = '' unless @subject?
    @subject = @subject.blue
    @title = @title.yellow
    @end = (->) unless @end?
    _data = (line) =>
      line = line.trim()
      return if line is ''
      ultra.reset(); ultra.print '[ ' + @title + ' ' + '] ' + @subject + ' [ ' + line.substr(0,100) + ' ] '
    shell.scriptline cmd, error : _data, line  : _data, end : ( => ultra.commit(); @end() )

switch (cmd = optimist.argv._.shift())
  when 'devgui'
    console.log '[', 'starting'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow, _base
    shell.script """
      cd "#{require('path').dirname __dirname}"
      LD_LIBRARY_PATH=#{_base}/node-webkit:$LD_LIBRARY_PATH "#{_base}/node-webkit/nw" .
    """
  when 'devinit'
    ultra = new  shell.Ultrashell
    console.log '[', 'boostrapping'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow,
      type[if type is 'linux' then 'green' else 'red'] + '[' + arch.grey + ']'
    url = "https://s3.amazonaws.com/node-webkit/v0.7.5/node-webkit-v0.7.5-#{type}-#{arch}.tar.gz"
    boostrap = new ync.Sync
      title : 'boostrap    '

      download_webkit : -> get = require('https').get url, (res) ->
        oldline = ''
        start = (new Date).getTime()
        length = parseInt res.headers['content-length']
        got = 0
        out = fs.createWriteStream(_base + '/node-webkit.tar.gz')
        res.on 'data', (data) ->
          now = (new Date).getTime()
          got += data.length
          percent = parseInt (got / length * 10).toFixed(0)
          progress = '##########'.substr(0,percent).green + '          '.substr(0,10-percent)
          speed = (got / (now - start) / 1024).toFixed(2) + ' mbps'
          line = '[ ' + 'downloading  '.yellow + '] ' + 'node-webkit '.blue + '[ ' + progress + ' ] '
          if (line isnt oldline) or (now - last > 0.5)
            last = now
            ultra.reset()
            ultra.print line + ' @ ' + speed
            oldline = line
          out.write data
        res.on 'error', ->
          console.log 'error downloading'.red, url
          process.exit 1
        res.on 'end', -> boostrap.proceed ultra.commit()

      install_webkit : -> new CLScript """
          cd #{_base} || exit 1
          rm -rf node-webkit
          tar xzvf node-webkit.tar.gz
          mv node-webkit-v0.7.5-#{type}-#{arch} node-webkit
          echo ok
        """, title : 'installing  ', subject : 'node-webkit', end : boostrap.proceed

      webkit_linux_workaround : -> new CLScript """
        f="/lib/x86_64-linux-gnu/libudev.so.1"
        test -f  "$f" && {
          ln -sf "$f" #{_base}/node-webkit/libudev.so.0 && echo ok || echo failed
        } || echo 'n/a'
        """, title : 'working_around  ', subject : 'node-webkit', end : boostrap.proceed

      install_nwgyp : -> new CLScript """
          sudo npm install -g nw-gyp
          echo ok
        """, title : 'installing  ', subject : 'nwgyp', end : boostrap.proceed

      install_opus : -> new CLScript """
          sudo apt-get install opus-tools build-essential
          echo ok
        """, title : 'installing  ', subject : 'opus, devtools', end : boostrap.proceed

      rebuild_buffertools : ->
        path = require.resolve('buffertools').split '/'
        path.pop()
        path = path.join '/'
        new CLScript """
          cd #{_base} || exit 1
          cp -r "#{path}" ./node-webkit
          cd ./node-webkit/buffertools
          nw-gyp rebuild --target=0.7.5
          echo ok
        """, title : 'rebuilding  ', subject : 'buffertools', end : boostrap.proceed
      done : -> process.exit 0

  else Kreem.init -> switch cmd
    when 'name'    then console.log Settings.name, 33023
    when 'port'    then console.log Tor.port, 33023
    when 'key'     then console.log Tor.hiddenService[if optimist.argv._.length > 0 then optimist.argv._.shift() else 'kreem'].pubkey
    when 'service' then console.log v.onion.red, v.port for k, v of Tor.hiddenService
    when 'id'      then console.log [ Settings.name + '@' + (s = Tor.hiddenService['kreem']).onion, s.pubkey ].join '\n'
    when 'tor'     then Tor.start (->)
    else Tor.start ->
      require('./kreem').listen
        addr   : '0.0.0.0'
        port   : optimist.argv.port || 33023
        nick   : Settings.name
        pubkey : 'lolcats'