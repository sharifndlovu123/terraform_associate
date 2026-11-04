# Autoloaded because of the name terraform.tfvars.
# db_password, worlds and world_map have no default in variables.tf, so they must be set here (or via -var / TF_VAR_*).

# Placeholder only, never commit a real secret
db_password = "example-only"

# list(string)
worlds = ["barsoom", "alloom", "darkoor", "meheuur", "bateem"]

# map(string)
world_map = {
  barsoom = "mars"
  alloom  = "earth"
  darkoor = "jupiter"
  meheuur = "venus"
  bateem  = "mercury"
}

# list(object({ mars_name, earth_name }))
worlds_splat = [
  { mars_name = "barsoom", earth_name = "mars" },
  { mars_name = "jassom", earth_name = "earth" },
  { mars_name = "sasoom", earth_name = "jupiter" },
  { mars_name = "cosoom", earth_name = "venus" },
]
