# Resources are the actual machines we're spinning up. It's in a format of
# <resource-type> <entity>. In our case we're using the type of
# "proxmox_vm_qemu" from the proxmox provider and naming it "k3s_masters"

resource "proxmox_vm_qemu" "k3s_master_pve1" {
  count       = data.sops_file.cluster_secrets.data["pve1_master_count"]
  name        = "${data.sops_file.cluster_secrets.data["pve1_master_name_prefix"]}${count.index + 1}"
  vmid        = "${data.sops_file.cluster_secrets.data["pve1_master_vmid_prefix"]}${count.index + 1}"
  target_node = data.sops_file.cluster_secrets.data["pve1_proxmox_node"]
  clone       = data.sops_file.cluster_secrets.data["pve1_clone_template_name"]
  full_clone  = false

  # basic VM settings here. agent refers to guest agent
  agent      = 1
  os_type    = "cloud-init"
  ci_wait    = 300
  ciuser     = data.sops_file.cluster_secrets.data["pve1_proxmox_vm_user"]
  cipassword = data.sops_file.cluster_secrets.data["pve1_proxmox_vm_password"]
  cores      = 6
  sockets    = 1
  cpu        = "kvm64"
  memory     = 8192
  scsihw     = "virtio-scsi-pci"
  bootdisk   = "virtio0"

  disk {
    slot = 0
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size     = "51200M"
    type     = "virtio"
    storage  = data.sops_file.cluster_secrets.data["pve1_master_storage"]
    iothread = 1
  }

  disk {
    slot = 1
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size     = "102400M"
    type     = "virtio"
    storage  = data.sops_file.cluster_secrets.data["pve1_node_storage"]
    iothread = 1
  }

  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # the ${count.index + 1} thing appends text to the end of the ip address
  # in this case, since we are only adding a single VM, the IP will
  # be 10.98.1.91 since count.index starts at 0. this is how you can create
  # multiple VMs and have an IP assigned to each (.91, .92, .93, etc.)
  ipconfig0 = "ip=${data.sops_file.cluster_secrets.data["pve1_master_ip"]}${count.index +1}${data.sops_file.cluster_secrets.data["pve1_master_subnet_mask"]},gw=${data.sops_file.cluster_secrets.data["pve1_master_gateway"]}"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
    ${data.local_file.public_key.content}
  EOF
}

resource "proxmox_vm_qemu" "k3s_node_pve1" {
  count       = data.sops_file.cluster_secrets.data["pve1_node_count"]
  name        = "${data.sops_file.cluster_secrets.data["pve1_node_name_prefix"]}${count.index + 1}"
  vmid        = "${data.sops_file.cluster_secrets.data["pve1_node_vmid_prefix"]}${count.index + 1}"
  target_node = data.sops_file.cluster_secrets.data["pve1_proxmox_node"]
  clone       = data.sops_file.cluster_secrets.data["pve1_clone_template_name"]
  full_clone  = false

  # basic VM settings here. agent refers to guest agent
  agent      = 1
  os_type    = "cloud-init"
  ci_wait    = 300
  ciuser     = data.sops_file.cluster_secrets.data["pve1_proxmox_vm_user"]
  cipassword = data.sops_file.cluster_secrets.data["pve1_proxmox_vm_password"]
  cores      = 6
  sockets    = 1
  cpu        = "kvm64"
  memory     = 32768
  scsihw     = "virtio-scsi-pci"
  bootdisk   = "virtio0"

  disk {
    slot = 0
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size     = "51200M"
    type     = "virtio"
    storage  = data.sops_file.cluster_secrets.data["pve1_node_storage"]
    iothread = 1
  }

  disk {
    slot = 1
    # set disk size here. leave it small for testing because expanding the disk takes time.
    size     = "102400M"
    type     = "virtio"
    storage  = data.sops_file.cluster_secrets.data["pve1_node_storage"]
    iothread = 1
  }
  # if you want two NICs, just copy this whole network section and duplicate it
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
  # not sure exactly what this is for. presumably something about MAC addresses and ignore network changes during the life of the VM
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  # the ${count.index + 1} thing appends text to the end of the ip address
  # in this case, since we are only adding a single VM, the IP will
  # be 10.98.1.91 since count.index starts at 0. this is how you can create
  # multiple VMs and have an IP assigned to each (.91, .92, .93, etc.)
  ipconfig0 = "ip=${data.sops_file.cluster_secrets.data["pve1_node_ip"]}${count.index + 1}${data.sops_file.cluster_secrets.data["pve1_node_subnet_mask"]},gw=${data.sops_file.cluster_secrets.data["pve1_node_gateway"]}"

  # sshkeys set using variables. the variable contains the text of the key.
  sshkeys = <<EOF
    ${data.local_file.public_key.content}
  EOF
}
