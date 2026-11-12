import "module" "tfplan-functions" {
  source = "../../tfplan-functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "mock-pass.sentinel"
  }
}

test {
  rules = {
    main = true
  }
}
