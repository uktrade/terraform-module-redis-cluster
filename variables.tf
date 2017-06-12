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
    id = "redis-exportopps"
    version = "latest"
    capacity = "3"
    internal = "true"
    port = "6379"
    sentinel.port = "26379"
    tls.port = "16379"
    tls.private_key = ".exportopps.stunnel.key"
    tls.certificate = ".exportopps.stunnel.pem"
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
