# Just enough resources so each provider is actually used
resource "random_pet" "name" {
  length = 2
}

resource "null_resource" "noop" {
  triggers = {
    pet = random_pet.name.id
  }
}

data "local_file" "hello" {
  filename = "${path.module}/hello.txt"
}

output "pet" {
  value = random_pet.name.id
}

output "hello" {
  value = trimspace(data.local_file.hello.content)
}
