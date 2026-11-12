#!/bin/bash
set -e
sudo yum install -y httpd
sudo systemctl enable httpd
