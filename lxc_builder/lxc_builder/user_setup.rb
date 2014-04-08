module UserSetup
  # TODO more logic!
  def user_setup
    chroot "useradd --create-home -s /bin/bash tango"
    chroot "sudo chpasswd", 'tango:tango'
  end
end
