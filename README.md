Better LXC Builder
=======

The available LXC templates (on our systems) are very complicated and inflexible. The ubuntu LXC template is a rather long and complicated bash script that makes it difficult to understand what is going on when an LXC is created and (perhaps more importantly) updating important variables is rather difficult difficult or left entirely up to the operator (eg ip address).

The aim of this project is to provide an interface which plugs into the lxc creation command just as the standard lxc templates available in ```/usr/lib/lxc/templates```, but provide useable output, readable code, enhanced configuration options, and more flexibility around the options given.

Prerequesites
------
- A linux distribution capable of creating and using LXC containers. This template has been developed and tested under ```Ubuntu 12.04```

Installation
------
- Clone the repository into the lxc template directory (Ubuntu default appears to be ```/usr/lib/lxc/templates```):

    $ sudo -s
    \# git clone git@github.com:robacarp/lxc_builder.git /usr/lib/lxc/templates/lxc_template

- Symlinx lxc_template/lxc-base into ```/usr/lib/lxc/templates``` so the lxc creator can find it.

Usage
------
Provide the ```builder``` to the lxc-create command: ```lxc-create -n NewLxcContainer77 -t builder```


State of development
=======
(2014-04-09) - The code is stabilizing out and is in use regularly, but should still be considered Alpha.

License
=======
See [the license file](LICENSE)
