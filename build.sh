#!/usr/bin/env bash

docker build --tag=caleb/vsftpd:3.0.3 .
docker tag caleb/vsftpd:3.0.3 caleb/vsftpd:latest
