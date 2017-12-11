

variable "Public_SSHKey" {
   description  = "Public SSH Key of the master server"
   default = ""
}
variable "Private_SSHKey" {
   description  = "Private SSH Key of the master server"
   default = ""
}

variable "aws_subnet" {
    description = "Subnet of the instance"
    default     = [ "subnet-9297fff7", "subnet-b69ff99c" ]
}

provider "aws" {
  region  = "us-east-1"
}


resource "aws_instance" "icpnode" {
  instance_type     = "t2.micro"
  count             = "1"
  ami               = "ami-aa2ea6d0"
  security_groups   = ["faststart2018-ec2"]
  key_name          = "Sri_Chow"
  subnet_id         = "${aws_subnet.default.id}"

  tags {
    Name = "ICPNode"
  	Owner = "Srinivas.chow"
  	}

    # Specify the ssh connection
    connection {
      user        = "ubuntu"
      private_key = "${var.Private_SSHKey}"
      host        = "${self.public_ip}"
    }

    provisioner "file" {
    content = <<EOF
  #!/bin/bash

  LOGFILE="/tmp/addkey.log"
  user_public_key=$1

  if [ "$user_public_key" != "None" ] ; then
      echo "---start adding user_public_key----" | tee -a $LOGFILE 2>&1
      echo "$user_public_key" | tee -a $HOME/.ssh/authorized_keys          >> $LOGFILE 2>&1 || { echo "---Failed to add user_public_key---" | tee -a $LOGFILE; exit 1; }
      echo "---finish adding user_public_key----" | tee -a $LOGFILE 2>&1
  fi

  EOF
  destination = "/tmp/addkey.sh"
    }

    # Execute the script remotely
    provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/addkey.sh; sudo bash /tmp/addkey.sh \"${var.Public_SSHKey}\"",
      ]
    }

}

output "New node ip address " {
  value = "${aws_instance.icpnode.private_ip}"
}
