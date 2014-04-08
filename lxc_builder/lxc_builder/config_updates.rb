module ConfigUpdates
  def update_configs
    p "updating config files"
    write_file 'etc/hosts', hosts
    write_file 'etc/network/interfaces', interfaces
    write_file 'etc/hostname', hostname

    #FIXME sure, put a .. in the file.
    write_file '../fstab', fstab

    rm_ttys
    update_lxc_config
    set_shm
    add_gateway_route

    true
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

  def fstab
    <<EOF
proc            proc         proc    nodev,noexec,nosuid 0 0
sysfs           sys          sysfs defaults  0 0
EOF
  end

  # shamelessly ripped off line for line from the ubuntu template,
  # without even having any idea what it does
  #
  # naming is hard
  def rest_of_lxc_config_file
    if File.exists?( File.join( options[:root], 'etc/init/container-detect.conf') )
      ttydir = "lxc"
    else
      ttydir = ""
    end

    <<-CONFIG
lxc.utsname = #{options[:name]}

lxc.devttydir =#{ttydir}
lxc.tty = 4
lxc.pts = 1024
lxc.rootfs = #{options[:root]}
lxc.mount  = #{options[:path]}/fstab
lxc.arch = #{options[:arch]}
lxc.cap.drop = sys_module mac_admin
lxc.pivotdir = lxc_putold

# uncomment the next line to run the container unconfined:
#lxc.aa_profile = unconfined

lxc.cgroup.devices.deny = a
# Allow any mknod (but not using the node)
lxc.cgroup.devices.allow = c *:* m
lxc.cgroup.devices.allow = b *:* m
# /dev/null and zero
lxc.cgroup.devices.allow = c 1:3 rwm
lxc.cgroup.devices.allow = c 1:5 rwm
# consoles
lxc.cgroup.devices.allow = c 5:1 rwm
lxc.cgroup.devices.allow = c 5:0 rwm
#lxc.cgroup.devices.allow = c 4:0 rwm
#lxc.cgroup.devices.allow = c 4:1 rwm
# /dev/{,u}random
lxc.cgroup.devices.allow = c 1:9 rwm
lxc.cgroup.devices.allow = c 1:8 rwm
lxc.cgroup.devices.allow = c 136:* rwm
lxc.cgroup.devices.allow = c 5:2 rwm
# rtc
lxc.cgroup.devices.allow = c 254:0 rwm
#fuse
lxc.cgroup.devices.allow = c 10:229 rwm
#tun
lxc.cgroup.devices.allow = c 10:200 rwm
#full
lxc.cgroup.devices.allow = c 1:7 rwm
#hpet
lxc.cgroup.devices.allow = c 10:228 rwm
#kvm
lxc.cgroup.devices.allow = c 10:232 rwm
CONFIG
  end

  def rm_ttys
    p "\t removing extra ttys"
    %w|tty5.conf tty6.conf|.each do |filename|
      FileUtils.rm_f( File.join(options[:root], '/etc/init', filename) )
    end
  end

  def update_lxc_config
    p "\t populating lxc config file"

    config_file = File.join(options[:path], 'config')
    lxc_config = File.read( config_file ).split("\n")
    veth_definitions = lxc_config.grep(/lxc\.network\.type[ \t]*=[ \t]*veth/).count
    hwaddr_definitions = lxc_config.grep(/lxc\.network\.hwaddr/).count

    # check to make sure that only one eth exist and make sure it has a mac address
    if veth_definitions == 1 && hwaddr_definitions == 0
      mac_address = "00:16:3e"
      3.times do
        # generate a random octet, minimum 0x10 so we don't have to pad the number
        octet = (rand(240) + 16).to_s(16)
        mac_address += ":" + octet
      end

      p "\t\033[32mMac Address: #{mac_address}\033[0m"
      lxc_config.push "lxc.network.hwaddr = " + mac_address
    end

    # assign an ip address TODO make this come from the options hash TODO make this smarter
    ip_address = "10.250.100." + (rand(55) + 100).to_s
    lxc_config.push "lxc.network.ipv4 = " + ip_address
    p "\t\033[32mIP Address: #{ip_address}\033[0m"

    File.open( config_file, 'w') do |file|
      file.puts *lxc_config
      file.puts rest_of_lxc_config_file
    end
  end

  def set_shm
    # I'm about 86.7% sure this is pointless...
    shm = File.join(options[:root], '/dev/shm')
    FileUtils.mv shm, shm+".bak"
    FileUtils.ln_s "/run/shm", shm
  end

  def add_gateway_route
    p "\tAdding default gateway"
    rc_local_path = File.join( options[:root], 'etc/rc.local' )
    rc_local = File.read(rc_local_path).split("\n")
    rc_local = rc_local.reject {|line| line =~ /exit/}
    rc_local.push "route add default gw 10.250.100.1"

    # I swear there was a 1 line way to do this...
    File.open rc_local_path, 'w' do |file|
      file.puts *rc_local
    end
  end
end
