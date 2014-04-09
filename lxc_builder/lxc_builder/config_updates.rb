require 'erb'
require 'ostruct'

module ConfigUpdates
  def update_configs
    p "updating config files"

    rm_ttys
    update_lxc_config
    set_shm
    add_gateway_route

    write_templates

    true
  end

  def write_templates
    write_file File.join(options[:root], 'etc/hosts'), hosts
    write_file File.join(options[:root], 'etc/network/interfaces'), interfaces
    write_file File.join(options[:root], 'etc/hostname'), hostname

    #FIXME sure, put a .. in the file.
    write_file File.join(options[:path], 'fstab'), fstab
  end

  def hostname
    options[:name]
  end

  def interfaces
    render( "templates/interfaces.erb" )
  end

  def hosts
    render( "templates/hosts.erb" )
  end

  def fstab
    render( "templates/fstab.erb" )
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

    render( "templates/lxc_config_footer.erb", {:ttydir => ttydir} )
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
    # I'm about 86.7% sure this is pointless...at least on our system
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

  private
  def render file, vars = {}
    vars = {:options => options}.merge(vars)
    context = OpenStruct.new(vars).instance_eval { binding }
    ERB.new( File.read(file) ).result( context )
  end
end
