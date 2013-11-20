## irac - 'a p2p instant messanger for tor'-ish

![irac logo](https://raw.github.com/hakt0r/irac/master/img/logo.png)

Built with nodejs upon Tor, TLS/SSL and OTR-Messaging,
irac is supposed to give you a peer-to-peer (audio-) chat solution that is
easy to set-up and easy to use.

This is work in progress and not ready for field use.

Similtar to [TorChat](https://github.com/prof7bit/TorChat).

### Installation
    $ sudo npm install irac (TODO: publish when ready ;)
    $ sudo npm install git://github.com/hakt0r/irac.git

### Usage
    $ irac     (normal usage)
    $ irac-gui (start gui, duh)
      --nick='anonymous'
      --port=33023
      --torport=9051
      --config=~/.irac
    $ irac id       (prints your user-id and public key)
    $ irac tor      (starts only the tor instance with hidden service)
    $ irac port     (prints the tor and irac port-numbers)
    $ irac devinit  (dowloads node-webit and rebuilds modules)
    $ irac devgui   (runs the node-webit gui, requires successful devinit)
    $ irac buildgui (builds the node-webkit gui, requires successful devinit)
    $ irac pack     (builds a releaseable node-webkit package)


### Copyrights
  * c) 2010-2013 Sebastian Glaser <anx@ulzq.de>
  * c) 2010-2011 Kreem
  * c) 2010,2013 flyc0r

### Licensed under GNU GPLv3

irac is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

irac is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this software; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

http://www.gnu.org/licenses/gpl.html
