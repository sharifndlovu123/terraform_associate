mock "tfplan/v2" {
  module {
    source = "mock-fail-type.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
