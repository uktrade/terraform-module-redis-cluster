variable "aws_conf" {
  type = "map"
  default = {}
}

variable "vpc_conf" {
  type = "map"
  default = {}
}

variable "redis_conf" {
  type = "map"
  default = {
    id = "redis"
    version = "latest"
    capacity = "1"
    internal = "true"
    port = "6379"
    auth = "pass"
    storage = "5"
    enc_key = "key"
  }
}

variable "subnet-type" {
  default = {
    "true" = "subnets_private"
    "false" = "subnets_public"
  }
}

variable "public_ip" {
  default = {
    "true" = "false"
    "false" = "true"
  }
}
