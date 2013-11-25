#!/usr/bin/env node

###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

require('./common') { GUI : false }

{ ync, optimist, DOTDIR, Tor, xl, Xhell, Xcript, Settings } = ( api = global.api )

_me  = 'cli'.blue; argv = optimist.argv

optimist.argv.debug = yes # REMOVEME: dev
if optimist.argv.debug?
  api.on 'tor.log', (line) -> Xhell.log '['+'tor'.yellow+'log]', line.trim().black

switch (cmd = optimist.argv._.shift())
  when 'devgui' then api.devgui()
  when 'devinit' then api.devinit (->), api.init.force = yes
  when 'init' then api.init (->), api.init.force = yes
  else api.init -> Settings.read -> switch cmd
    when 'id'    then console.log [ Settings.name + '@' + (s = Tor.hiddenService['kreem']).onion, s.pubkey ].join '\n'
    when 'key'   then console.log Tor.hiddenService[if optimist.argv._.length > 0 then optimist.argv._.shift() else 'kreem'].pubkey
    when 'tor'   then Tor.start -> api.on 'tor.log', console.log
    when 'name'  then console.log Settings.name, 33023
    when 'port'  then console.log Tor.port, 33023
    when 'buddy' then console.log Settings
    when 'service' then console.log v.onion.red, v.port for k, v of Tor.hiddenService
    else api.listen()