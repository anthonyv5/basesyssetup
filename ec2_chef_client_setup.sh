#!/bin/bash

set -e -x

mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

RPM_SYS=0
APT_SYS=0

#which rpm > /dev/null 2>&1
which apt-get > /dev/null 2>&1
if [ "$?" = "0" ] ; then
  APT_SYS=1
  pmapp=apt-get
else
  RPM_SYS=1
  pmapp=rpm  
fi

# START SETUP BASE SYSTEM
$pmapp -y install screen

# ncurses term for ansi-term in emacs
$pmapp -y install ncurses-term
if ! [ -a /usr/share/terminfo/e/eterm-color ]; then
  ln -s /usr/share/terminfo/e/eterm /usr/share/terminfo/e/eterm-color
fi

## screen config

echo export HISTSIZE=9000 | tee -a /etc/skel/.bash_profile | tee -a /root/.bash_profile
cat <<"EOS"| tee /etc/skel/.screenrc | tee /root/.screenrc | tee /home/ubuntu/.screenrc
source /etc/screenrc
defscrollback 9000
termcapinfo xterm 'hs:ts=\E]2;:fs=\007:ds=\E]2;screen\007'
defhstatus "screen ^A (^Aa) | $USER@^AH"
hardstatus off
caption always "%{Yk} %H%{k}|%{W}%-w%{+u}%n %t%{-u}%+w"
caption string "%{yk}%H %{Kk}%{g}%-w%{kR}%n %t%{Kk}%{g}%+w"
startup_message off
vbell off
EOS




## SUDO defaults
sed -ire '/NOPASSWD/ s/^# //' /etc/sudoers # %sudo doesn't need a password now!

# add our public keys to all new users, and to the default user
mkdir -p /etc/skel/.ssh
#curl http://codecafe.com/chris/ssh.pub | tee -a /etc/skel/.ssh/authorized_keys
#curl http://codecafe.com/taylor/ssh.pub | tee -a /etc/skel/.ssh/authorized_keys
# curl http://codecafe.com/wayne/ssh.pub | tee -a /etc/skel/.ssh/authorized_keys
#curl http://codecafe.com/wayne/ssh-backup.pub | tee -a /etc/skel/.ssh/authorized_keys

if ! grep chris@codecafe.com /root/.ssh/authorized_keys ; then
   wget -nv -O - http://codecafe.com/chris/ssh.pub   | tee -a /etc/skel/.ssh/authorized_keys | tee -a /root/.ssh/authorized_keys
fi

if ! grep taylor@codecafe.com /root/.ssh/authorized_keys ; then
  wget -nv -O - http://codecafe.com/taylor/ssh.pub  | tee -a /etc/skel/.ssh/authorized_keys | tee -a /root/.ssh/authorized_keys
fi

if ! grep wayne /root/.ssh/authorized_keys ; then
   wget -nv -O - http://codecafe.com/wayne/ssh.pub   | tee -a /etc/skel/.ssh/authorized_keys | tee -a /root/.ssh/authorized_keys
fi

if ! grep backuppc@blackhole /root/.ssh/authorized_keys ; then
   wget -nv -O - http://codecafe.com/wayne/ssh-backup.pub   | tee -a /etc/skel/.ssh/authorized_keys | tee -a /root/.ssh/authorized_keys
fi

cat <<"EOS"| tee -a /tmp/setup_ssh_access 
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
cat /etc/skel/.ssh/authorized_keys >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
EOS
chmod +x /tmp/setup_ssh_access

su - ubuntu -c "sh /tmp/setup_ssh_access"
su - ec2-user -c "sh /tmp/setup_ssh_access"
# END SETUP BASE SYSTEM

wget -nv -O - http://www.opscode.com/chef/install.sh | sudo bash
set +x
true