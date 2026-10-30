# remote-exec and file need a reachable SSH host, so this folder is validate-only unless you have one:
#   terraform init && terraform validate
terraform {
  required_version = ">= 1.5.0"
}

variable "host" {
  type    = string
  default = "203.0.113.10" # documentation-range IP, replace with a real host to apply
}

variable "user" {
  type    = string
  default = "ubuntu"
}

variable "private_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

resource "terraform_data" "remote" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = file(pathexpand(var.private_key_path))
    # bastion_host = "..."   # connect through a bastion; also bastion_user, bastion_private_key, ...
    # type = "winrm" for Windows
  }

  # file: copy local file/dir to the target (source, or content, plus destination)
  provisioner "file" {
    content     = "deployed by terraform\n"
    destination = "/tmp/deploy.txt"
  }

  # remote-exec: one mode only: inline, script or scripts
  provisioner "remote-exec" {
    inline = [
      "cat /tmp/deploy.txt",
      "hostname",
    ]
  }
}
