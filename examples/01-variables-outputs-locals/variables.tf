variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "availability_zone_names" {
  type    = list(string)
  default = ["eu-west-1a"]
}

variable "docker_ports" {
  type = list(object({
    internal = number
    external = number
    protocol = string
  }))
  default = [
    {
      internal = 8080
      external = 80
      protocol = "tcp"
    }
  ]
}

variable "db_password" {
  type      = string
  sensitive = true
}
