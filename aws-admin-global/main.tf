
resource "terraform_data" "this" {
  for_each = var.inputs

  input = {
    key     = each.key
    example = each.value
  }
}
