# count: N identical copies, count.index starts at 0
resource "terraform_data" "server" {
  count = var.server_count
  input = "node-${count.index}"
}

# count as an on/off switch
resource "terraform_data" "extra" {
  count = var.enable_extra ? 1 : 0
  input = "extra"
}

# for_each over a map: each.key / each.value
resource "terraform_data" "group" {
  for_each = {
    core      = "eu-west"
    analytics = "us-east"
  }
  input = {
    name     = each.key
    location = each.value
  }
}

# for_each over a list: wrap in toset(), each.key is the element
resource "terraform_data" "user" {
  for_each = toset(["ana", "ben", "chi", "dev"])
  input    = each.key
}

# depends_on: explicit ordering when there is no reference between resources
resource "terraform_data" "first" {
  input = "step-one"
}

resource "terraform_data" "second" {
  input      = "step-two"
  depends_on = [terraform_data.first]
}

# lifecycle
resource "terraform_data" "lifecycle_demo" {
  input = "v1"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [input] # editing input above will not trigger an update
    # prevent_destroy     = true    # makes terraform destroy fail on this resource
  }
}
