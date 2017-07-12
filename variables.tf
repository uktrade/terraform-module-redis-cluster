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
    capacity = "3"
    internal = "true"
    port = "6379"
    sentinel.port = "26379"
    tls.port = "16379"
    tls.private_key = ".stunnel.key"
    tls.certificate = ".stunnel.pem"
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
