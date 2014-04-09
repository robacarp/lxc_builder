LXC Builder Template
=======

The available LXC templates (on our systems) are very complicated and inflexible. The ubuntu LXC template is a rather long and complicated bash script that makes it difficult to understand what is going on when an LXC is created and (perhaps more importantly) updating important variables is rather difficult difficult or left entirely up to the operator (eg ip address).

The aim of this project is to provide an interface which plugs into the lxc creation command just as the standard lxc templates available in ```/usr/lib/lxc/templates```, but provide useable output, readable code, enhanced configuration options, and more flexibility around the options given.

State of development
=======
(2014-04-09) - The code is stabilizing out and is in use regularly, but should still be considered Alpha.

License
=======
See [the license file](LICENSE)
