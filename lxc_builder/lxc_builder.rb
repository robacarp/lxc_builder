require 'lxc_builder/options'
require 'lxc_builder/rootfs'
require 'lxc_builder/config_updates'
require 'lxc_builder/user_setup'
require 'open3'

class LXCBuilder
  include Options
  include Rootfs
  include ConfigUpdates
  include UserSetup

  def self.build
    self.new
  end

  def initialize
    parse
    make_rootfs &&
    update_configs &&
    user_setup
  end

  def write_file path, data
    File.open File.join(options[:root], path), 'w' do |f|
      f << data
    end
  end

  def cache_chroot command, input
    e("chroot #{options[:cache_dir]} #{command}", input)
  end

  def chroot command, input = nil
    e("chroot #{options[:root]} #{command}", input)
  end

  def e command, input = nil
    # TODO pty this
    puts "executing: " + command
    err, output = '', ''

    Open3.popen3 command do |stdin, stdout, stderr, process|
      unless input.nil?
        stdin.print input
      end
      stdin.close

      err = stderr.read.strip
      output = stdout.read.strip
      stderr.close
      stdout.close
    end

    status = $?.to_i

    puts "stdout: "+ output
    puts "stderr: "+ err
    puts "exit status: " + status.to_s
  end

  def run
    ensure_root_cache
    copy_cache_to_root
  end

  def p *args
    puts *args
    $stdout.flush
  end
end
