#!/bin/sh
sudo apt-get update
sudo apt-get install stress
stress -c 1 -m 1 --vm-bytes 300M
