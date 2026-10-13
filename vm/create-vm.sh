#!/bin/bash
# Создание VM в KVM (WSL2). Запускать в отдельной папке, не в репозитории.
set -e
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
wget -nc https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
cat > user-data << EOT
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_ed25519.pub)
EOT
cloud-localds seed.iso user-data
sudo cp noble-server-cloudimg-amd64.img /var/lib/libvirt/images/lab.img
sudo qemu-img resize /var/lib/libvirt/images/lab.img 15G
sudo cp seed.iso /var/lib/libvirt/images/
sudo virt-install --name lab-vm --memory 2048 --vcpus 2 \
  --disk /var/lib/libvirt/images/lab.img \
  --disk /var/lib/libvirt/images/seed.iso,device=cdrom \
  --os-variant ubuntu24.04 --import \
  --network network=default --noautoconsole
