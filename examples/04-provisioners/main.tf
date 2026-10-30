variable "release" {
  type    = string
  default = "v1"
}

# local-exec: runs on the machine running terraform, after the resource is created
resource "terraform_data" "local_exec" {
  input = "web-1"

  provisioner "local-exec" {
    command = "echo \"created $NAME (id ${self.id})\""

    environment = {
      NAME = self.input
    }
  }

  # destroy-time provisioner: can only reference self
  provisioner "local-exec" {
    when    = destroy
    command = "echo destroying ${self.id}"
  }
}

# interpreter + working_dir
resource "terraform_data" "interpreter" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = path.module
    command     = "echo running in $(basename $PWD) with $0"
  }
}

# null_resource: needs the null provider. triggers re-run the provisioners when a value changes.
resource "null_resource" "main" {
  triggers = {
    release = var.release
  }

  provisioner "local-exec" {
    command = "echo null_resource release ${self.triggers.release}"
  }
}

# terraform_data: same idea, built in, no provider. triggers_replace replaces the resource.
resource "terraform_data" "main" {
  triggers_replace = [var.release]

  provisioner "local-exec" {
    command = "echo terraform_data release ${var.release}"
  }
}
