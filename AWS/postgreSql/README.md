# Create PostgreSQL on AWS


**Required Inputs**
* AWS Access Key and Access Secret
* AWS subnet id where the worker node will be provisioned
* AWS private key to talk to the provisioned worker node
* AMI of the image
* Security group with 8080 open

**Import to CAM**
* Create a cloud connection with AWS Access key and Secret
* Menu ==> Templates ==> Create Template ==> From GitHub => Enter the following ino
  * GIT URL: https://github.com/chowdhu/CAM
  * GitHub Access Token: <>
  * GitHub Repository sub-directory: /AWS/postgreSql
  * Save

**Deploy Template**

* Menu ==> Templates ==> look for template "Deploy PostgreSQL to AWS"
* Modify the input params accordingly
* Deploy
