build {
  name    = "ubuntu-2404"
  sources = ["source.proxmox-clone.ubuntu-2404"]

  # # Provisioning the VM Template
  # provisioner "shell" {
  #   inline = [
  #     "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
  #     "sudo systemctl enable qemu-guest-agent",
  #     "sudo systemctl start qemu-guest-agent",
  #     "sudo cloud-init clean",
  #     "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
  #     "sudo rm -f /etc/netplan/00-installer-config.yaml",
  #     "echo 'Ubuntu 24.04 Template by Packer - Creation Date: $(date)' | sudo tee /etc/issue"
  #   ]
  # }

  # # Install Docker
  # provisioner "shell" {
  #   inline = [
  #     "echo 'Installing Docker...'",
  #     "# Add Docker's official GPG key",
  #     "sudo apt-get update",
  #     "sudo apt-get install -y ca-certificates curl gnupg",
  #     "sudo install -m 0755 -d /etc/apt/keyrings",
  #     "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
  #     "sudo chmod a+r /etc/apt/keyrings/docker.gpg",

  #     "# Add the Docker repository",
  #     "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",

  #     "# Pin Docker version",
  #     "echo 'Package: docker-ce' | sudo tee /etc/apt/preferences.d/docker-ce",
  #     "echo 'Pin: version 5:27.5.1*' | sudo tee -a /etc/apt/preferences.d/docker-ce",
  #     "echo 'Pin-Priority: 999' | sudo tee -a /etc/apt/preferences.d/docker-ce",

  #     "# Install Docker",
  #     "sudo apt-get update",
  #     "sudo apt-get install -y docker-ce=5:27.5.1* docker-ce-cli=5:27.5.1* containerd.io docker-buildx-plugin docker-compose-plugin",

  #     "# Add ubuntu user to docker group",
  #     "sudo usermod -aG docker ubuntu",

  #     "# Enable Docker service",
  #     "sudo systemctl enable docker",

  #     "# Verify installation",
  #     "docker --version",
  #     "docker compose version",

  #     "echo 'Docker installation complete!'"
  #   ]
  # }

  # # Added provisioner to forcibly eject ISO and prepare for reboot
  # provisioner "shell" {
  #   inline = [
  #     "echo 'Completed installation. Preparing for template conversion...'",
  #     "echo 'Ejecting CD-ROM devices...'",
  #     "sudo eject /dev/sr0 || true",
  #     "sudo eject /dev/sr1 || true",
  #     "echo 'Removing CD-ROM entries from fstab if present...'",
  #     "sudo sed -i '/cdrom/d' /etc/fstab",
  #     "sudo sync",
  #     "echo 'Setting disk as boot device...'",
  #     "sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub",
  #     "sudo update-grub",
  #     "echo 'Clearing cloud-init status to ensure fresh start on first boot...'",
  #     "sudo cloud-init clean --logs",
  #     "echo 'Installation and cleanup completed successfully!'"
  #   ]
  #   expect_disconnect = true
  # }
}