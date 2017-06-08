resource "aws_iam_role" "node-role" {
  name = "${var.aws_conf["domain"]}-redis-role-${var.redis_conf["id"]}"
  assume_role_policy = "${file("${path.module}/policies/default-role.json")}"
}

resource "aws_iam_role_policy" "node-default-policy" {
  name = "${var.aws_conf["domain"]}-redis-default-policy-${var.redis_conf["id"]}"
  policy = "${file("${path.module}/policies/default-policy.json")}"
  role = "${aws_iam_role.node-role.id}"
}

resource "aws_iam_instance_profile" "node-profile" {
  name = "${var.aws_conf["domain"]}-redis-profile-${var.redis_conf["id"]}"
  path = "/"
  role = "${aws_iam_role.node-role.name}"

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "route53_policy" {
  template = "${file("${path.module}/policies/route53-policy.json")}"

  vars {
    zone_id = "${var.vpc_conf["zone_id"]}"
  }
}

resource "aws_iam_role_policy" "route53" {
  name = "${var.aws_conf["domain"]}-redis-route53-policy-${var.redis_conf["id"]}"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${aws_iam_role.node-role.name}"
}
