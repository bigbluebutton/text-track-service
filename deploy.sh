#!/bin/bash
#/usr/local/bin/docker-compose -f /var/docker/text-track-service/docker-compose.yml down -v
sudo systemctl stop tts-docker
cd /var/docker/text-track-service
git pull
sudo -kS chmod -R a+rX *
sudo -kS chmod -R a+rX tmp/*
sudo systemctl start tts-docker
#/usr/local/bin/docker-compose -f /var/docker/text-track-service/docker-compose.yml up --build -d
