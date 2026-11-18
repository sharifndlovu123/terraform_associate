# Run with: terraform test        (terraform test -verbose shows each plan/state)
# Each `run` block is one step; blocks run in order and share state.

# plan only: nothing is created
run "default_names" {
  command = plan

  assert {
    condition     = length(output.names) == 2
    error_message = "expected two servers by default"
  }

  assert {
    condition     = output.names[0] == "web-dev-0"
    error_message = "first server should be named web-dev-0"
  }
}

# apply: really creates the (built-in) resources, then destroys them when the file ends
run "prod_with_three" {
  command = apply

  variables {
    env            = "prod"
    instance_count = 3
  }

  assert {
    condition     = output.names[2] == "web-prod-2"
    error_message = "third server should be named web-prod-2"
  }
}

# a negative test: the run passes only if the variable validation fails
run "rejects_bad_env" {
  command = plan

  variables {
    env = "qa"
  }

  expect_failures = [var.env]
}
