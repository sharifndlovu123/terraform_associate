output "root_pet" {
  value = random_pet.root.id
}

output "aliased_pet" {
  value = random_pet.aliased.id
}

output "module_greeting" {
  value = module.greeting.message # module outputs are read as module.<name>.<output>
}
