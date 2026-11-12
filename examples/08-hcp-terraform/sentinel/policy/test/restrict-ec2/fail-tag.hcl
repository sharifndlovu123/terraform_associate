mock "tfplan/v2" {
  module {
    source = "mock-fail-tag.sentinel"
  }
}

test {
  rules = {
    main = false
  }
}
