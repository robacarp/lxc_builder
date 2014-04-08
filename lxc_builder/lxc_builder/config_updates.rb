module ConfigUpdates
  def update_configs
    write_file 'etc/hosts', hosts
    write_file 'etc/network/interfaces', interfaces
    write_file 'etc/hostname', hostname
  end

  def hostname
    options[:name]
  end

  def interfaces
    <<-EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
EOF
  end

  def hosts
    <<-EOF
127.0.0.1   localhost
127.0.1.1   #{hostname}

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
   EOF
  end
end
