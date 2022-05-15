data "sops_file" "cluster_secrets" {
  source_file = "secret.sops.yaml"
}

data "local_file" "public_key" {
  filename = data.sops_file.cluster_secrets.data["pve2_ssh_pub_key_file"]
}

#################
#   Resources   #
#################
# Terraform docs: https://www.terraform.io/cli
# Proxmox docs: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
# Proxmox docs qemu: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs/resources/vm_qemu
# Useful article: https://austinsnerdythings.com/2021/09/01/how-to-deploy-vms-in-proxmox-with-terraform/

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.6"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

# Providers are what we are provisioning to. This can be something AWS, Azure,
# ect. In our case we're using Proxmox installed by the above provider plugin.
provider "proxmox" {
  pm_api_url          = data.sops_file.cluster_secrets.data["pve2_proxmox_url"]
  pm_api_token_id     = data.sops_file.cluster_secrets.data["pve2_proxmox_api_token_id"]
  pm_api_token_secret = data.sops_file.cluster_secrets.data["pve2_proxmox_api_token_secret"]
  pm_parallel         = 2
  pm_timeout          = 600
  pm_tls_insecure     = true
#  pm_debug            = true
#  pm_log_enable       = true
#  pm_log_file         = "terraform-plugin-proxmox.log"
#  pm_log_levels = {
#    _default    = "debug"
#    _capturelog = ""
#  }
}
