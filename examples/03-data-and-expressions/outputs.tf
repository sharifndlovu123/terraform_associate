output "data_source" {
  value = trimspace(data.local_file.greeting.content)
}

# Types
output "types" {
  value = {
    string = "ami-0example"
    number = 3.14
    bool   = true
    list   = ["eu-west-1a", "eu-west-1b"]
    map    = { tier = "gold", weight = 2 }
    null   = null
  }
}

# Strings: interpolation and %{ } directives
output "interpolation" {
  value = "Welcome, ${var.name}."
}

output "directive" {
  value = "Welcome, %{if var.name != ""}${var.name}%{else}guest%{endif}."
}

# Heredoc with a for directive; the trailing ~ strips the whitespace the directive leaves behind
output "heredoc" {
  value = <<EOT
%{for ip in local.ips~}
host ${ip}
%{endfor~}
EOT
}

# Operators and conditionals (both branches must be the same type)
output "operators" {
  value = {
    math    = (2 + 3) * 4 % 7
    compare = 5 >= 3
    logic   = true && !false
    ternary = var.name != "" ? var.name : "fallback"
    mixed   = true ? tostring(12) : "hello"
  }
}

# Named values
output "named_values" {
  value = {
    module_path = path.module
    workspace   = terraform.workspace
  }
}
