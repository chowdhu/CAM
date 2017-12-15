# Install Tomcat and PostgreSQL on AWS 
Currently tested on ubuntu

**Required Inputs**
* AWS Access Key and Access Secret
* AWS subnet id where the worker node will be provisioned
* AWS private key to talk to the provisioned worker node
* AMI of the image

**prep work**

**Import to CAM**
* Create a cloud connection with AWS Access key and Secret
* Menu ==> Templates ==> Create Template ==> From GitHub => Enter the following ino
  * GIT URL: https://github.com/chowdhu/CAM
  * GitHub Access Token: <>
  * GitHub Repository sub-directory: /AWS/addworkernode
  * Save

**Deploy Template**

* Menu ==> Templates ==> look for template ""
* Modify the input params accordingly
* Deploy
