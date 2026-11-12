import "module" "tfplan-functions" {
  source = "../../tfplan-functions.sentinel"
}

mock "tfplan/v2" {
  module {
    source = "mock-fail.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
