###
 
  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac 

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###


require('./common') { GUI : false }

{ ync, optimist, DOTDIR, Tor, shell, ultra } = ( api = global.api )

_me   = 'cli'.blue

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
    console.log '[', 'starting'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow, DOTDIR
    args = ''; for k,v of optimist.argv
      continue if k is '$0' or k is '_'
      args += """ --#{k}='#{v}'"""
    console.log args
    shell.script """
      cd "#{require('path').dirname __dirname}"
      LD_LIBRARY_PATH=#{DOTDIR}/node-webkit:$LD_LIBRARY_PATH \\
        "#{DOTDIR}/node-webkit/nw" . #{args}
    """
  when 'devinit' then api.init ->
    console.log '[', 'boostrapping'.yellow, ']', 'irac'.cyan + '/' + 'v0.9'.magenta + '-' + 'kreem'.yellow,
      os.type[if os.type is 'linux' then 'green' else 'red'] + '[' + os.arch.grey + ']'
    url = "https://s3.amazonaws.com/node-webkit/v0.7.5/node-webkit-v0.7.5-#{os.type}-#{os.arch}.tar.gz"
    boostrap = new ync.Sync
      title : 'boostrap    '

      download_webkit : -> get = require('https').get url, (res) ->
        oldline = ''
        start = (new Date).getTime()
        length = parseInt res.headers['content-length']
        got = 0
        out = fs.createWriteStream(DOTDIR + '/node-webkit.tar.gz')
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
          cd #{DOTDIR} || exit 1
          rm -rf node-webkit
          tar xzvf node-webkit.tar.gz
          mv node-webkit-v0.7.5-#{os.type}-#{os.arch} node-webkit
          echo ok
        """, title : 'installing  ', subject : 'node-webkit', end : boostrap.proceed

      webkit_linux_workaround : -> new CLScript """
        f="/lib/x86_64-linux-gnu/libudev.so.1"
        test -f  "$f" && {
          ln -sf "$f" #{DOTDIR}/node-webkit/libudev.so.0 && echo ok || echo failed
        } || echo 'n/a'
        """, title : 'workaround  ', subject : 'node-webkit', end : boostrap.proceed

      install_nwgyp : -> new CLScript """
          sudo npm install -g nw-gyp
          echo ok
        """, title : 'installing  ', subject : 'nwgyp', end : boostrap.proceed

      install_devtools : -> new CLScript """
          sudo apt-get install opus-tools build-essential make awk g++ nodejs nodejs-dev libotr5 libotr5-dev
          echo ok
        """, title : 'installing  ', subject : 'opus, devtools', end : boostrap.proceed

      rebuild_buffertools : ->
        path = require.resolve('buffertools').split '/'
        path.pop()
        path = path.join '/'
        new CLScript """
          cd #{DOTDIR} || exit 1
          cp -r "#{path}" ./node-webkit
          cd ./node-webkit/buffertools
          nw-gyp rebuild --target=0.7.5
          echo ok
        """, title : 'rebuilding  ', subject : 'buffertools', end : boostrap.proceed

      rebuild_otr4 : ->
        path = require.resolve('otr4').split '/'
        path.pop()
        path = path.join '/'
        new CLScript """
          cd #{DOTDIR} || exit 1
          cp -r "#{path}" ./node-webkit
          cd ./node-webkit/otr4
          nw-gyp rebuild --target=0.7.5
          echo ok
        """, title : 'rebuilding  ', subject : 'otr4', end : boostrap.proceed

      done : -> process.exit 0

  else api.init -> switch cmd
    when 'name'    then console.log Settings.name, 33023
    when 'port'    then console.log Tor.port, 33023
    when 'key'     then console.log Tor.hiddenService[if optimist.argv._.length > 0 then optimist.argv._.shift() else 'kreem'].pubkey
    when 'service' then console.log v.onion.red, v.port for k, v of Tor.hiddenService
    when 'id'      then console.log [ Settings.name + '@' + (s = Tor.hiddenService['kreem']).onion, s.pubkey ].join '\n'
    when 'tor'     then Tor.start -> api.on 'tor.log', console.log
    else api.listen()