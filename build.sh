#!/usr/bin/env bash

docker build --tag=caleb/vsftpd:3.0.2 .
docker tag -f caleb/vsftpd:3.0.2 caleb/vsftpd:latest
