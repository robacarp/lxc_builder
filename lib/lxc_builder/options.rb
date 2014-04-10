require 'optparse'

module Options
  attr :options

  def parse
    @options = {
      :arch        => 'amd64',
      :cache_dir   => '/var/cache/lxc/ruby-ci',
      :gateway     => nil,
      :ip          => nil,
      :name        => 'lxc-container-' + rand(35).to_s,
      :mac         => nil,
      :purge_cache => false,
      :path        => '',
      :root        => nil
    }

    OptionParser.new do |opts|
      opts.banner = "TODO"

      opts.on("--path PATH","Specify the path to the lxc configuration directory") do |path|
        @options[:path] = path
      end

      opts.on("--name NAME","Indicate the desired name of the container") do |name|
        @options[:name] = name
      end

      opts.on("--flush-cache","remove and re download lxc cache with debootstrap") do |flush|
        p "setting flush to " + flush.inspect
        @options[:flush_cache] = flush
      end

      opts.on("--ip-address IP","the ip address of the new lxc container. ex: 10.250.100.112/22") do |ip|
        @options[:ip] = ip
      end

      opts.on("--gateway IP","the gateway address of the new lxc container") do |gateway|
        @options[:gateway] = gateway
      end

      opts.on("--mac-address MAC", "the mac address (or mac prefix) of the lxc network interface") do |mac|
        @options[:mac] = mac
      end
    end.parse!

    @options[:root] = @options[:path] + '/rootfs'
    @options[:cache_dir] = @options[:cache_dir][0...-1] if @options[:cache_dir][-1].chr == '/'

    if @options[:ip].nil?
      @options[:ip] = rand_ip
    end

    # try and guess at the gateway by copying the ip, but swapping the last octet with 1
    if @options[:gateway].nil? && ! @options[:ip].nil?
      ip = @options[:ip].split('.')
      ip.pop
      ip.push 1
      @options[:gateway] = ip.join('.')
    end

    if @options[:gateway].nil?
      p "\033[33m WARN:\033[0m No gateway specified. LXC will not have network fully configured"
    end

    # default first 3 octets
    if @options[:mac].nil?
      @options[:mac] = "00:16:3e"
    end

    # random the rest of the octets
    octets = @options[:mac].split(':').reject {|e| e.nil? }
    until octets.length >= 6
      # generate a random octet, minimum 0x10 so we don't have to pad the number
      octets.push( (rand(240) + 16).to_s(16) )
    end
    @options[:mac] = octets.first(6).join(':')
  end

  def rand_ip
    return "10.250.100." + (rand(55) + 100).to_s
  end
end
