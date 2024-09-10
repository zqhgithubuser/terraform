resource "aws_lb" "httpd" {
  name               = "${var.namespace}-lb"

  load_balancer_type = "application"
  subnets            = [ var.subnet.subnetA_id, var.subnet.subnetB_id ]
  security_groups    = [ var.sg.lb.id ]
  # depends_on         = [ aws_internet_gateway_attachment.default ]
}

resource "aws_lb_listener" "httpd" {
  load_balancer_arn = aws_lb.httpd.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "httpd" {
  name     = "${var.namespace}-target-group"

  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "httpd" {
  listener_arn = aws_lb_listener.httpd.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.httpd.arn
  }
}
