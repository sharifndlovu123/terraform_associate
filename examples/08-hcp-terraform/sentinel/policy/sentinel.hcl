# Lists the policies in this set, in the order they are evaluated.
policy "restrict-ec2" {
  source            = "./restrict-ec2.sentinel"
  enforcement_level = "hard-mandatory" # advisory | soft-mandatory | hard-mandatory
}
