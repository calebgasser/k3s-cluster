resource "local_file" "inventory" {
  content = templatefile("inventory.tmpl", {
    k3s_master = proxmox_vm_qemu.k3s_master,
    k3s_node = proxmox_vm_qemu.k3s_node
  })
  filename = "../cluster-ansible/inventory/inventory.ini"
}
