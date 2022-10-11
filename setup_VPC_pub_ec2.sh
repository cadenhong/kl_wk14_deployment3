#!/bin/bash

# Script to install required packages
# For Deployment 3 - run this inside Kura VPC's public EC2
# or copy and paste the content inside "User Data" while configuring EC2

sudo apt update && sudo apt upgrade -y
sudo apt install -y default-jre python3-pip python3.10-venv nginx