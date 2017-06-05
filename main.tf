data "aws_ami" "redis-ami" {
  most_recent = true
  name_regex = "ubuntu-xenial-16.04-amd64-server"
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }
}

data "template_file" "redis-cloudinit" {
  template = "${file("${path.module}/cloudinit.yml")}"

  vars {
    aws_region = "${var.vpc_conf["region"]}"
    dns_zone_id = "${var.vpc_conf["zone_id"]}"
    cluster_id = "${var.aws_conf["domain"]}"
    cluster_asg = "${var.aws_conf["domain"]}-redis"
    redis_version = "${var.redis_conf["version"]}"
  }
}

resource "aws_launch_configuration" "redis" {
  name_prefix = "${var.aws_conf["domain"]}-redis-"
  image_id = "${data.aws_ami.redis-ami.id}"
  instance_type = "${var.aws_conf["instance_type"]}"
  key_name = "${var.aws_conf["key_name"]}"
  iam_instance_profile = "${aws_iam_instance_profile.node-profile.id}"
  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.redis.id}"
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    delete_on_termination = false
  }
  user_data = "${data.template_file.redis-cloudinit.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "redis" {
  name = "${var.aws_conf["domain"]}-redis"
  launch_configuration = "${aws_launch_configuration.redis.name}"
  vpc_zone_identifier = ["${data.aws_subnet.redis_az.id}"]
  min_size = "${var.reds_conf["capacity"]}"
  max_size = "${var.reds_conf["capacity"]}"
  desired_capacity = "${var.reds_conf["capacity"]}"
  wait_for_capacity_timeout = 0

  tag {
    key = "Name"
    value = "${var.aws_conf["domain"]}-redis"
    propagate_at_launch = true
  }
  tag {
    key = "Stack"
    value = "${var.aws_conf["domain"]}"
    propagate_at_launch = true
  }
  tag {
    key = "clusterid"
    value = "${var.aws_conf["domain"]}"
    propagate_at_launch = true
  }
  tag {
    key = "host-type"
    value = "redis"
    propagate_at_launch = true
  }
  tag {
    key = "svc"
    value = "redis"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "redis" {
  name = "${var.aws_conf["domain"]}-redis"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = ["${aws_security_group.redis-elb.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-redis"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "redis-elb" {
  name = "${var.aws_conf["domain"]}-redis-elb"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = ["${var.vpc_conf["security_group"]}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-redis"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "redis" {
  name = "${element(split(".", var.aws_conf["domain"]), 0)}-redis-elb"
  subnets = ["${split(",", var.vpc_conf[lookup(var.subnet-type, var.redis_conf["internal"])])}"]

  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.redis-elb.id}"
  ]

  listener {
    lb_port            = 6379
    lb_protocol        = "tcp"
    instance_port      = 6379
    instance_protocol  = "tcp"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 10
    target              = "TCP:6379"
    interval            = 10
  }

  connection_draining = true
  cross_zone_load_balancing = true
  internal = true

  tags {
    Stack = "${var.aws_conf["domain"]}"
    Name = "${var.aws_conf["domain"]}-redis-elb"
  }
}

resource "aws_route53_record" "redis" {
   zone_id = "${var.vpc_conf["zone_id"]}"
   name = "redis.${var.aws_conf["domain"]}"
   type = "A"
   alias {
     name = "${aws_elb.redis.dns_name}"
     zone_id = "${aws_elb.redis.zone_id}"
     evaluate_target_health = false
   }

   lifecycle {
     create_before_destroy = true
   }
}
