provider "aws" {
  region  = "us-east-1"
}
variable "Public_SSHKey" {
   description  = "Public SSH Key of the master server"
   default = ""
}
variable "ssh_key_path" {
  description = "Path to master private SSH key, this should be copied into /home/terraform dir of the container"
  default = "/home/terraform/master_key"
}
variable "ssh_key_path_worker" {
  description = "Path to worker private SSH key, this should be copied into /home/terraform dir of the container"
  default = "/home/terraform/id_aws_chow"
}
variable "master_ip" {
    description = "IP address of the master"
    default     = "169.48.64.249"
}
variable "aws_instancetype" {
    description = "AWS Instance type"
    default     = "t2.medium"
}
variable "aws_keyname" {
    description = "Keyname used to provision the ICP cluster"
    default     = "Sri_Chow"
}
variable "aws_subnet" {
    description = "Subnet of the instance"
    default     = [ "subnet-9297fff7", "subnet-b69ff99c" ]
}
variable "aws_ami" {
    description = "AWS AMI Image"
    default     = "ami-aa2ea6d0"
}
variable "master_icp_installdir" {
    description = "Install directory of the master"
    default     = "/opt/icp210/cluster"
}

resource "aws_instance" "icpnode" {
  instance_type     = "${var.aws_instancetype}"
  ami               = "${var.aws_ami}"
  key_name          = "${var.aws_keyname}"
  security_groups   = ["sg-a4febad1"]
  subnet_id         = "${var.aws_subnet[0]}"
  root_block_device {
        volume_size = "100"
  }

  tags {
    Name = "ICPWorkerNode"
  	Owner = "Srinivas.chow"
  	}
}

output "New node ip address " {
  value = "${aws_instance.icpnode.private_ip}"
}

resource "null_resource" "worker_node_sshkeys" {

    depends_on = ["aws_instance.icpnode"]

    # Specify the ssh connection
    connection {
      user        = "ubuntu"
      private_key = "${file(var.ssh_key_path_worker)}"
      host        = "${aws_instance.icpnode.public_ip}"
    }

    provisioner "file" {
      source = "${var.ssh_key_path}"
      destination = "/tmp/master_key"
    }

    provisioner "file" {
    content = <<EOF
    #!/bin/bash

    LOGFILE="/tmp/addkey.log"
    user_public_key=$1
    if [ "$user_public_key" != "None" ] ; then
        echo "---start adding user_public_key----" | tee -a $LOGFILE 2>&1
        echo "$user_public_key" | tee -a /root/.ssh/authorized_keys          >> $LOGFILE 2>&1 || { echo "---Failed to add user_public_key---" | tee -a $LOGFILE; exit 1; }
        cp /tmp/master_key /root/.ssh/master_key
        chmod 400 /root/.ssh/master_key
        #This removes the junk added by aws from authorized_keys to permit root login
        sudo sed -i.bak 's/.*ssh-rsa/ssh-rsa/' /root/.ssh/authorized_keys
        echo "---finish adding user_public_key----" | tee -a $LOGFILE 2>&1
    fi

    EOF
    destination = "/tmp/addkey.sh"
    }
    provisioner "remote-exec" {
      inline = [
        "sudo chown root.root /tmp/addkey.sh;chmod 4755 /tmp/addkey.sh; sudo bash /tmp/addkey.sh \"${var.Public_SSHKey}\"",
      ]
    }
  }

resource "null_resource" "worker_node_prereqs" {

    depends_on = ["null_resource.worker_node_sshkeys"]

    # Specify the ssh connection, this time you can connect using root
    connection {
      user        = "root"
      private_key = "${file(var.ssh_key_path_worker)}"
      host        = "${aws_instance.icpnode.public_ip}"
    }

    provisioner "file" {
    content = <<EOF
  #!/bin/bash
  echo "---start prereqs----"
  #stopping firewall
  sudo service ufw stop
  sudo systemctl disable ufw

  #Update the source registry
  sudo sysctl -w vm.max_map_count=262144

  #Some docker pre-req packages
  sudo apt-get update -y
  sudo apt-get install -y python unzip nfs-common jq
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  #docker-ce installation
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce
  service docker start
  sudo apt-get install -y python-pip
  sudo docker version
  echo "---End prereqs------"

  EOF
  destination = "/tmp/prereqs.sh"
  }
    provisioner "remote-exec" {
	  inline = "bash /tmp/prereqs.sh > /tmp/prereqs.log"
	}
}

#For some reason I had to download the image here and do a docker load
resource "null_resource" "worker_node_loadDockerImages" {
  depends_on = ["null_resource.worker_node_prereqs"]

  # Specify the ssh connection, this time you can connect using root
  connection {
    user        = "root"
    private_key = "${file(var.ssh_key_path_worker)}"
    host        = "${aws_instance.icpnode.public_ip}"
  }
  provisioner "remote-exec" {
  inline = [
    "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/master_key \"${var.master_ip}:/${var.master_icp_installdir}/images/ibm-cloud-private-x86_64-2.1.0.tar.gz\" /opt; cd /opt; tar xf ibm-cloud-private-x86_64-2.1.0.tar.gz -O | sudo docker load > /tmp/loaddockerImg.log ",  ]
}
}

resource "null_resource" "worker_node_installwk" {

    depends_on = ["null_resource.worker_node_loadDockerImages"]

    # Specify the ssh connection, this time you can connect using root
    connection {
      user        = "root"
      private_key = "${file(var.ssh_key_path_worker)}"
      host        = "${aws_instance.icpnode.public_ip}"
    }

    # This creates a file on worker, scp the file to master and then executes the file on master from worker
    provisioner "file" {
    content = <<EOF
    #!/bin/bash
    #This script will be copied to the master and executed
    WORKER_IP=$1
    #Install directory is upto cluster
    ICP_INSTALL_DIR=$2
    cd $ICP_INSTALL_DIR
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ssh_key /etc/hosts $WORKER_IP:/etc/hosts
    docker run -e LICENSE=accept --net=host  -v "$(pwd)":/installer/cluster ibmcom/icp-inception:2.1.0-ee install -l $WORKER_IP
    EOF
    destination = "/tmp/addNode.sh"
    }
      provisioner "remote-exec" {
      inline = [
        "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/master_key /tmp/addNode.sh \"${var.master_ip}:/tmp\"; ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /root/.ssh/master_key \"${var.master_ip}\" '/bin/bash /tmp/addNode.sh \"${aws_instance.icpnode.public_ip}\" \"${var.master_icp_installdir}\"' > /tmp/installwk.log ",
      ]
    }
    }
