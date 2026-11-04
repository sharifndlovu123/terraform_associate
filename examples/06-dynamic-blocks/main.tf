# archive_file has a repeatable nested block called "source" (one zip entry each).
# Writing it out by hand would mean one fixed block per file; dynamic generates them from data.
data "archive_file" "bundle" {
  type        = "zip"
  output_path = "${path.module}/build/bundle.zip"

  # 1) Iterate a map. The iterator is named after the block, so use source.key / source.value.
  dynamic "source" {
    for_each = var.files

    content {
      filename = source.key
      content  = source.value
    }
  }

  # 2) Iterate a list of objects with a custom iterator name instead of "source".
  dynamic "source" {
    for_each = var.extra_files
    iterator = extra

    content {
      filename = extra.value.name
      content  = extra.value.text
    }
  }

  # 3) Iterate a SET of strings. Sets have no separate key, so source.key and source.value are the same string.
  #    The content below shows both, to prove it.
  dynamic "source" {
    for_each = var.placeholder_files

    content {
      filename = source.key
      content  = "key=${source.key} value=${source.value}"
    }
  }

  # 4) Optional block: a one-item list creates the block once, an empty list creates none.
  dynamic "source" {
    for_each = var.include_license ? [1] : []

    content {
      filename = "LICENSE"
      content  = "example only"
    }
  }
}
