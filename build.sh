#!/bin/bash

sudo dnf update -y
sudo dnf install wget libguestfs libguestfs-tools-c

# This URL will need to be updated
if ! (echo "e83f02b4a3e89e342e97a741dc09bfb5050b826c763441b65f1a8e1b5e5184b8  Kali-2020.1-cloud-amd64.tar.gz" | sha256sum --check --status); then
    wget https://images.offensive-security.com/virtual-images/kali-linux-2020.1-vbox-amd64.ova
fi
tar xvf kali-linux-2020.1-vbox-amd64.ova
qemu-img convert -f vmdk -O raw Kali-Linux-2020.1-vbox-amd64-disk001.vmdk disk.raw

# Virt-Customize Magic
# shellcheck disable=SC2016
virt-customize -a disk.raw \
               --edit "/etc/default/grub:s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/" \
               --edit "/etc/default/grub:s/quiet/console=ttyS0,38400n8d/" \
               --run-command "/usr/sbin/update-grub" \
               --run-command "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -" \
               --run-command "curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -" \
               --write "/etc/apt/sources.list.d/google-compute-engine.list:deb http://packages.cloud.google.com/apt google-compute-engine-buster-stable main" \
               --write "/etc/apt/sources.list.d/debian.list:deb http://deb.debian.org/debian buster main contrib non-free" \
               --write "/etc/apt/sources.list.d/docker.list:deb https://download.docker.com/linux/debian buster stable" \
               --run-command "apt update" \
               --run-command "DEBIAN_FRONTEND=noninteractive apt upgrade -y" \
               --uninstall gdm3,virtualbox-guest-dkms,virtualbox-guest-utils,docker,docker-engine,docker.io \
               --install kali-defaults,kali-root-login,desktop-base,xfce4,xfce4-places-plugin,xfce4-goodies,xrdp \
               --install google-osconfig-agent,python-google-compute-engine,python3-google-compute-engine,google-compute-engine-oslogin,google-compute-engine \
               --install docker-ce \
               --run-command 'curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose' \
               --run-command "chmod +x /usr/local/bin/docker-compose" \
               --run-command "ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose" \
               --run-command 'curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64' \
               --run-command 'chmod +x minikube' \
               --run-command 'install minikube /usr/local/bin/' \
               --run-command 'curl -LO https://github.com/derailed/popeye/releases/download/v0.6.1/popeye_0.6.1_Linux_x86_64.tar.gz' \
               --run-command 'tar zxvf popeye_0.6.1_Linux_x86_64.tar.gz' \
               --run-command 'chmod +x popeye' \
               --run-command 'install popeye /usr/local/bin/' \
               --run-command 'curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.3.3/krew.{tar.gz,yaml}"' \
               --run-command 'tar zxvf krew.tar.gz' \
               --run-command './krew_linux_amd64 install --manifest=krew.yaml --archive=krew.tar.gz' \
               --run-command './krew_linux_amd64 update' \
               --run-command 'curl -sfL https://get.k3s.io | sh -' \
               --run-command "systemctl enable ssh" \
               --run-command "systemctl enable google-osconfig-agent.service" \
               --run-command "systemctl enable docker" \
               --run-command "systemctl set-default graphical.target" \
               --run-command "systemctl enable xrdp-sesman" \
               --run-command "systemctl enable xrdp" \
               --run-command "userdel -r kali" \
               --firstboot-command "sleep 300 && apt upgrade -y"

virt-sysprep -a disk.raw

tar --format=oldgnu -Sczf Kali-2020.1-cloud-amd64.tar.gz disk.raw 
gsutil cp  Kali-2020.1-cloud-amd64.tar.gz gs://darkwolf-image-uploads/Kali-2020.1-cloud-amd64.tar.gz
gcloud compute images create kali-2020-1-cloud --source-uri gs://darkwolf-image-uploads/Kali-2020.1-cloud-amd64.tar.gz
