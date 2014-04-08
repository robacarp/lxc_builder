require 'optparse'

module Options
  attr :options

  def parse
    @options = {
      :cache_dir => '/var/cache/lxc/ruby-ci',
      :purge_cache => false,
      :path => '',
      :name => 'lxc-container-' + rand(35).to_s
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
    end.parse!

    @options[:root] = @options[:path] + '/rootfs'
    @options[:cache_dir] = @options[:cache_dir][0...-1] if @options[:cache_dir][-1].chr == '/'
  end
end
