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

global.GUI = true

require './js/common'
_base    = global._base
colors   = global.colors
optimist = global.optimist
fs       = global.fs
ync      = global.ync
shell    = global.shell
Tor      = global.Tor
Kreem    = global.Kreem
Player   = global.Player
Recorder = global.Recorder
Stream   = global.Stream
Settings = global.Settings
Peer     = global.Peer

global.$ = $
global.cerosine = cerosine = require './js/cerosine'
global.Text     = Text     = cerosine.Text
global.eMail    = eMail    = cerosine.eMail
global.Field    = Field    = cerosine.Field
global.Dialog   = Dialog   = cerosine.Dialog
global.Button   = Button   = cerosine.Button
global.Password = Password = cerosine.Password
global.File     = File     = cerosine.File

console.log "WK_base:", _base

Kreem.init ->
  gui = require 'nw.gui'
  
  tray = new gui.Tray
    title : 'irac'
    icon  : 'img/logo.png'

  menu = new gui.Menu();
  menu.append new gui.MenuItem type:  'checkbox', label: 'Online'
  menu.append new gui.MenuItem type:  'checkbox', label: 'Talk', click : -> Recorder.toggle()
  menu.append new gui.MenuItem label: 'Settings'
  menu.append new gui.MenuItem type:  'separator'
  menu.append new gui.MenuItem label: 'Quit', click : -> process.exit(0)
  tray.menu = menu

  Tor.start ->
    optimist = require 'optimist'
    listen = Kreem.listen
      addr   : '0.0.0.0'
      port   : optimist.argv.port || 33023
      nick   : Settings.name
      pubkey : 'lolcats'

  $(document).ready ->
    $('body').append '<div id="dialogs"></div>'
    Dialog.frame = $('#dialogs')

    update_profile = ->
      setTimeout ( ->
        $('#profile > .nick').html Settings.name
        $('#profile > .avatar').attr 'src', 'file://' + Settings.avatarPath
      ), 1000
    update_profile()

    # Recorder (logo button)
    ptt = $('#logo').on 'click', -> Recorder.toggle()
    Recorder.on 'start', -> ptt.addClass 'down'
    Recorder.on 'stop',  -> ptt.removeClass 'down'

    # 'Add Buddy' Dialog
    addBuddy = new Dialog
      id : 'addBuddy'
      form : buddyAddress : type : eMail, title : 'Buddy Address'
      btn :
        cancel  : title : 'Cancel',    click : -> @toggle()
        default : title : 'Add Buddy', click : ->
          Kreem.connect addBuddy.$.find("input").val()
          @toggle()
    add = $('#add').on 'click', -> addBuddy.toggle()

    # 'Settings' Dialog
    settings = new Dialog
      id : 'settings'
      form :
        nick   : type : Text, value: Settings.name, title : 'Public Nickname'
        avatar : type : File, title : 'Avatar'
      btn :
        cancel  : title : 'Cancel', click : -> @toggle()
        default : title : 'Save',   click : ->
          copy = (src,dst,cb) ->
            rd = fs.createReadStream(src)
            wr = fs.createWriteStream(dst)
            wr.on 'close', cb
            rd.pipe(wr)
          Settings.name = @$.find('#nick').val()
          files = @$.find('input[type="file"]')[0].files
          ext   = files[0].path.split('.').pop()
          path  = "#{_base}/avatar.#{ext}"
          copy files[0].path, path, =>
            Settings.avatarPath = path
            Settings.save =>
              @toggle()
              update_profile()
    add = $('#settings').on 'click', -> settings.toggle()

    # 'Upload' Dialog
    upload = new Dialog
      id : 'upload'
      form :
        nick   : type : Text, title : 'Title'
        avatar : type : File, title : 'Avatar'
      btn :
        cancel  : title : 'Cancel', click : -> @toggle()
        default : title : 'Save',   click : ->
    add = $('#upload').on 'click', -> upload.toggle()

    # Handle Kreem's events
    History = $ '#history'
    Buddys  = $ '#buddys'
    Kreem.on 'connection', (info) ->
      History.prepend """
        <div class="message" data-onion="#{info.onion}">
          <img  class="avatar" src="img/anonymous.svg" />
          <span class="nick">#{info.user}</span>
          <span class="text">(connected)</span>
        </div>"""
      Buddys.append """
        <span class="buddy" data-onion="#{info.onion}">
          <img  class="avatar" src="img/anonymous.svg" />
          <span class="nick">#{info.user}</span>
        </span>"""
    Kreem.on 'message', (info, message) -> History.prepend """
      <div class="message" data-onion="#{info.onion}">
        <img  class="avatar" src="img/anonymous.svg" />
        <span class="nick">#{info.user}</span>
        <span class="text">#{message}</span>
      </div>"""
