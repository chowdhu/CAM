# Create PostgreSQL on AWS


**Required Inputs**
* AWS Access Key and Access Secret
* Verison of PostgreSQL
* Db name of PostgreSQL
* userid and password of PostgreSQL
* Default port 5432

**Import to CAM**
* Create a cloud connection with AWS Access key and Secret
* Menu ==> Templates ==> Create Template ==> From GitHub => Enter the following info
  * GIT URL: https://github.com/chowdhu/CAM
  * GitHub Access Token: <>
  * GitHub Repository sub-directory: /AWS/postgreSql
  * Save

**Deploy Template**

* Menu ==> Templates ==> look for template "Deploy PostgreSQL to AWS"
* Modify the input params accordingly
* Deploy
