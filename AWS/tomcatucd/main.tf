variable "azs" {
   type        = "list"
   description = "List of availability zones that instance can be provisioned to"
   default     = [ "us-east-1a", "us-east-1b" ]
}

variable "aws_keyname" {
    description = "Keyname used to provision the ICP cluster"
    default     = "Sri_Chow"
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
    default     = "t2.micro"
}
provider "aws" {
    region     = "us-east-1"
}
variable "aws_dbversion" {
    description = "PostgreSQl engine version"
    default     = "9.6.5"
}
variable "aws_dbinstancetype" {
    description = "AWS Instance type"
    default     = "db.t2.micro"
}
variable "aws_dbname" {
    description = "Name of the database"
    default     = "mydb"
}
variable "aws_dbuid" {
    description = "Userid of the database"
    default     = "dbuser"
}
variable "aws_dbpwd" {
    description = "Password of the database"
    default     = "passw0rd"
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
    target              = "HTTP:8080/examples/"
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
  key_name          = "${var.aws_keyname}"
  vpc_security_group_ids = ["sg-a4febad1"]

  user_data =  <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y tomcat7-webapps tomcat7-admin-webapps
sudo service tomcat7 start
sudo chkconfig tomcat7 on

EOF

tags {
  Name = "UCDTomcatPostreSql"
  Owner = "Srinivas.chow"
  }
}

resource "aws_db_instance" "postgresql" {

  allocated_storage         = "10"
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "${var.aws_dbversion}"
  instance_class            = "${var.aws_dbinstancetype}"
  name                      = "${var.aws_dbname}"
  username                  = "${var.aws_dbuid}"
  password                  = "${var.aws_dbpwd}"
  multi_az                  = false
  storage_encrypted         = false
  skip_final_snapshot       = true
  final_snapshot_identifier = "terraform-aws-postgresql-rds-snapshot"

  tags {
    Name = "ChowPostgreSQL"
    Owner = "Srinivas.chow"
  }
}

output "loadbalancer" {
   value = "http://${aws_elb.web.dns_name}"
}

output "PostgreSQL port" {
  value = "${aws_db_instance.postgresql.port}"
}
output "PostgreSQL endpoint" {
  value = "${aws_db_instance.postgresql.endpoint}"
}
