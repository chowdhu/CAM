# Add AWS worker node to ICP
Currently tested on ubuntu

**Required Inputs**
* AWS Access Key and Access Secret
* AWS subnet id where the worker node will be provisioned
* AWS private key to talk to the provisioned worker node
* AMI of the image
* ICP private and public key
* ICP boot/master node IP address
* Install directory of ICP

**prep work**
* Copy the private keys into the cam terraform container
* On master do the following
  * kubectl get pods -n services | grep terraform ( make a note of the pod)
  * kubectl -n services cp <master_privatekey> <pod> :/home/terraform/master_key
  * kubectl -n services cp <aws_private key> <pod> :/home/terraform/id_aws_chow
  * kubectl -n services exec provider-terraform-local-1455837184-7958f -it /bin/bash ( connect to the container in a shell)
  * cd /home/terraform and modify permissions and ID
   * chown terraform:terraform master_key
   * chown terraform:terraform id_aws_chow
   * chmod 400 on both keys

**Import to CAM**
* Create a cloud connection with AWS Access key and Secret
* Menu ==> Templates ==> Create Template ==> From GitHub => Enter the following ino
  * GIT URL: https://github.com/chowdhu/CAM
  * GitHub Access Token: <>
  * GitHub Repository sub-directory: /AWS/addworkernode
  * Save

**Deploy Template**

* Menu ==> Templates ==> look for template "Add ICP woker node to AWS"
* Modify the input params accordingly
* Deploy
