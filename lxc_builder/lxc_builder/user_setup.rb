module UserSetup
  # TODO more logic!
  def user_setup
    p "Creating user"
    chroot "useradd --create-home -s /bin/bash tango"
    chroot "sudo chpasswd", 'tango:tango'
    p "\tcomplete"
  end
end
