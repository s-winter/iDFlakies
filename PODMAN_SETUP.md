This file documents changes that were made to a Ubuntu 18.04 system to get rootless podman running for cgroups v2 resource throttling support.

To check if the installed kernel (4.15.0-76) had cgroups v2 support:
grep cgroup /proc/filesystems

First, systemd had to be configured to use cgroups v2 by editing the kernel boot parameters in /etc/default/grub:
GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"
cgroups v2 should be used by default in newer systemd versions. The one on the machine I used was 237 and did not support it out of the box as far as I could tell.

In a next step, crun had to be installed:
git clone https://github.com/containers/crun
cd crun
# build dependencies...
apt-get install -y make git gcc build-essential pkgconf libtool \
   libsystemd-dev libcap-dev libseccomp-dev libyajl-dev \
   go-md2man libtool autoconf python3 automake
./autogen.sh && ./configure
make
sudo make install

To install podman:
. /etc/os-release
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/x${NAME}_${VERSION_ID}/Release.key -O Release.key
sudo apt-key add - < Release.key
sudo apt-get update -qq
sudo apt-get -qq -y install podman

Running podman worked out of the box with the above install, but --memory-swap=-1 was not supported. Opened a ticket at
https://github.com/containers/libpod/issues/5091
which got fixed:
https://github.com/containers/libpod/pull/5098
But I'm still suffering from the error described there. Needs more work, which I will document here once I got it running.