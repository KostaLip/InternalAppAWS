variable "region" {
  default = "eu-central-1"
}

variable "password" {
  type = string
  sensitive = true
}