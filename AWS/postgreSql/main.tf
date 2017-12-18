provider "aws" {
    region     = "us-east-1"
}
variable "aws_dbversion" {
    description = "PostgreSQl engine version"
    default     = "9.4.4"
}
variable "aws_instancetype" {
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
resource "aws_db_instance" "postgresql" {

  allocated_storage    = "10"
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "${var.aws_dbversion}"
  instance_class       = "${var.aws_instancetype}"
  name                 = "${var.aws_dbname}"
  username             = "${var.aws_dbuid}"
  password             = "${var.aws_dbpwd}"
  multi_az             = false
  storage_encrypted    = false

  tags {
    Name = "ChowPostgreSQL"
    Owner = "Srinivas.chow"
  }
}

output "New node ip address " {
  value = "${aws_db_instance.postgresql.public_ip}"
}
