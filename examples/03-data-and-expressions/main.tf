# Data source: read something defined outside this config, reference with data.<type>.<name>
data "local_file" "greeting" {
  filename = "${path.module}/greeting.txt"
}

variable "name" {
  type    = string
  default = ""
}

locals {
  ips = ["192.168.1.10", "192.168.1.11"]
}
