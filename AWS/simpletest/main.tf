provider "aws" {
    region     = "us-east-1"
}
variable "aws_ami" {
    description = "AWS AMI Image"
    default     = "ami-55ef662f"
}
variable "aws_instancetype" {
    description = "AWS Instance type"
    default     = "t2.micro"
}
variable "aws_keyname" {
    description = "Keyname used to provision the ICP cluster"
    default     = "Sri_Chow"
}
variable "aws_subnet" {
    description = "Subnets"
    default     = [ "subnet-9297fff7", "subnet-b69ff99c" ]
}
resource "aws_instance" "web" {
  ami               = "${var.aws_ami}"
  key_name          = "${var.aws_keyname}"
  instance_type     = "${var.aws_instancetype}"
  count             = "1"
  security_groups   = ["sg-a4febad1"]
  subnet_id         = "${var.aws_subnet[0]}"

  user_data =  <<EOF
#!/bin/bash
sudo yum update -y
sudo yum install -y tomcat7-webapps tomcat7-admin-webapps
sudo service tomcat7 start
sudo chkconfig tomcat7 on

EOF
  tags {
    Name = "ChowTomcat"
  	Owner = "Srinivas.chow"
  	}

}

output "New node ip address " {
  value = "${aws_instance.web.public_ip}"
}
