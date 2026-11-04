output "tags" {
  value       = terraform_data.app.output.tags
  description = "Common tags applied to everything"
}

output "db_password" {
  value     = var.db_password
  sensitive = true # hidden in the terminal, still plain text in the state file
}

output "world_planets" {
  value       = local.world_planets
  description = "Each requested world and its planet"
}

output "non_earth_worlds" {
  value       = [for w, p in var.world_map : w if p != "earth"]
  description = "Every world in the map not on earth (for expression with an if filter)"
}

# Splat: [*] pulls one attribute out of every element of a list
output "worlds_splat_names" {
  value = {
    mars  = var.worlds_splat[*].mars_name
    earth = var.worlds_splat[*].earth_name
  }
  description = "mars_name and earth_name of every world, using splat"
}

# The splat above is shorthand for this for expression.
# A splat returns a list but [for ...] returns a tuple, and == compares types too, so wrap the for in tolist().
output "splat_matches_for" {
  value       = var.worlds_splat[*].mars_name == tolist([for w in var.worlds_splat : w.mars_name])
  description = "true when the splat and the long for expression give the same values"
}
