# Lists the policies in this set, in the order they are evaluated.
policy "restrict-ec2" {
  source            = "./restrict-ec2.sentinel"
  enforcement_level = "hard-mandatory" # advisory | soft-mandatory | hard-mandatory
}

# restrict-azs imports the shared tfplan-functions module (download it first, see the README)
module "tfplan-functions" {
  source = "./tfplan-functions.sentinel"
}

policy "restrict-azs" {
  source            = "./restrict-azs.sentinel"
  enforcement_level = "advisory"
}
