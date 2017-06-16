#!/bin/sh

yum install -y  epel-release
yum -y update
yum -y install python-pip
pip install --upgrade pip
pip install flask
pip install boto3
pip install awscli
pip install pandas
