#!/bin/bash

sudo dnf update -y
sudo dnf install wget libguestfs libguestfs-tools-c

# This URL will need to be updated
wget https://images.offensive-security.com/virtual-images/kali-linux-2020.1-vbox-amd64.ova
tar xvf kali-linux-2020.1-vbox-amd64.ova
qemu-img convert -f vmdk -O raw Kali-Linux-2020.1-vbox-amd64-disk001.vmdk disk.raw

# Virt-Customize Magic

virt-customize -a disk.raw \
               --uninstall gdm3 \
               --install cloud-init,kali-defaults,kali-root-login,desktop-base,xfce4,xfce4-places-plugin,xfce4-goodies \
               --run-command "systemctl enable cloud-init" \
               --run-command "systemctl enable ssh" \
               --run-command "systemctl set-default graphical.target"
               --edit "/etc/default/grub:s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/" \
               --edit "/etc/default/grub:s/quiet/console=ttyS0,38400n8d/"

tar --format=oldgnu -Sczf Kali-2020.1-cloud-amd64.tar.gz disk.raw 
gsutil cp  Kali-2020.1-cloud-amd64.tar.gz gs://darkwolf-image-uploads/Kali-2020.1-cloud-amd64.tar.gz
gcloud compute images create kali-2020-1-cloud --source-uri gs://darkwolf-image-uploads/Kali-2020.1-cloud-amd64.tar.gz
