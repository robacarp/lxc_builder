require 'fileutils'

module Rootfs
  def make_rootfs
    ensure_root_cache && copy_cache_to_root
  end

  def build_root_fs dir
    binary = 'debootstrap'

    components = "main,universe"
    arch = options[:arch]
    packages = [:vim, :ssh, :curl]
    release = "precise"
    mirror = "http://archive.ubuntu.com/ubuntu"
    security_mirror = "http://security.ubuntu.com/ubuntu"

    command = [
      binary,
      '--verbose',
      "--components=#{components}",
      "--arch=#{arch}",
      "--include=#{packages.map(&:to_s).join(',')}",
      release, dir, mirror
    ].join(' ')

    p command
    exec command
  end

  # TODO this doesn't seem to work...
  def valid_root_cache?
    return true
    (! options[:purge_cache]) && File.directory?(options[:cache_dir])
  end

  def ensure_root_cache
    if valid_root_cache?
      true
    else
      p 'Root FS cache is invalid, preparing'
      p `rm -rf #{options[:cache_dir]}`
      build_root_fs options[:cache_dir]

      p 'updating apt'
      cache_chroot 'apt-get update'

      true
    end
  end

  def copy_cache_to_root
    # essentially: FileUtils.cp_r options[:cache_dir], options[:path]
    # but ruby doesn't know how to copy device files, so we'll shell out.
    # FYI, it seems like this behaves differently when logged into an interactive
    # shell rather then running from a script...
    command = "rsync -a #{options[:cache_dir]}/ #{options[:root]}"
    p "Copying rootfs to #{options[:root]}"
    p "\t" + command
    e command
    p "\t\033[32m" + "copying complete" + "\033[0m"

    true
  end
end
