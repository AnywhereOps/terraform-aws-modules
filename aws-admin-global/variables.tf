variable "inputs" {
  description = "Map of inputs to create. Keys are used as identifiers."
  type        = map(string)
  default = {
    default = "test"
  }
}
