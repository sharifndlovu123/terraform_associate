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

variable "world_map" {
  type        = map(string)
  description = "World name to the planet it sits on"
}

variable "worlds" {
  type        = list(string)
  description = "Worlds to look up in world_map, in order"
}

variable "worlds_splat" {
  type = list(object({
    mars_name  = string
    earth_name = string
  }))
  description = "Worlds with the name used on Mars and the name used on Earth, for splat ([*]) examples"
}
