variable "files" {
  type        = map(string)
  description = "Zip entry name to its text content"
  default = {
    "hello.txt"      = "hello from a dynamic block"
    "docs/notes.md"  = "- one source block per map entry"
    "config/app.ini" = "mode = demo"
  }
}

variable "extra_files" {
  type = list(object({
    name = string
    text = string
  }))
  description = "A second collection, to show a custom iterator name"
  default = [
    { name = "extra/one.txt", text = "first extra" },
    { name = "extra/two.txt", text = "second extra" },
  ]
}

variable "placeholder_files" {
  type        = set(string)
  description = "A set of names: for a set, key and value are both the element"
  default     = ["placeholders/a.txt", "placeholders/b.txt"]
}

variable "include_license" {
  type        = bool
  description = "Adds a LICENSE entry when true"
  default     = false
}
