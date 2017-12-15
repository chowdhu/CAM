variable "azs" {
   type        = "list"
   description = "List of availability zones that instance can be provisioned to"
   default     = [ "us-east-1a", "us-east-1b" ]
}

variable "KeyPair_Name" {
   description  = "Desired name of the AWS key pair"
   default = ""
}

variable "Public_SSHKey" {
   description  = "Public SSH Key"
   default = ""
}

variable "aws_subnet" {
    description = "Subnet for the ELB"
    default     = [ "subnet-9297fff7", "subnet-b69ff99c" ]
}

variable "ElasticLoadBalancer_Name" {
    description = "Elastic Load Balancer Name"
    default = "CAMUCD-ELB"
}
variable "aws_ami" {
    description = "AWS AMI Image"
    default     = "ami-55ef662f"
}
variable "aws_instancetype" {
    description = "AWS Instance type"
    default     = "t2.macro"
}
provider "aws" {
    region     = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.KeyPair_Name}"
  public_key = "${var.Public_SSHKey}"
}


resource "aws_elb" "web" {
  name = "${var.ElasticLoadBalancer_Name}"

  # The same availability zone as our instance
  subnets         = ["${var.aws_subnet}"]
  security_groups = ["sg-a47df2d1"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/index.html"
    interval            = 5
  }

  # The instance is registered automatically
  instances                   = ["${aws_instance.web.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_lb_cookie_stickiness_policy" "default" {
  name                     = "lbpolicy"
  load_balancer            = "${aws_elb.web.id}"
  lb_port                  = 80
  cookie_expiration_period = 600
}

resource "aws_instance" "web" {
  instance_type     = "${var.aws_instancetype}"
  count             = "2"
  availability_zone = "${element(var.azs,count.index)}"
  ami               = "${var.aws_ami}"
  key_name          = "${aws_key_pair.deployer.key_name}"
  security_groups   = ["sg-a4febad1"]


  user_data =  <<EOF
#!/bin/bash
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on
myIP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
echo 'My IP ==>'$myIP
cat << EOFF > /var/www/html/index.html
<html>
<body>
<h1>Welcome to my Web Page</h1>
<hr/>
<p>MY IP:$myIP </p>
<hr/>
</body>
</html>
EOFF
EOF

  tags {
    Name = "instance-elb-${count.index}"
  }
}

output "loadbalancer" {
   value = "http://${aws_elb.web.dns_name}"
}
