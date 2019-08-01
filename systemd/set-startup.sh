#!/bin/bash
#set -e

# Setup Faktory password
cp start-text-track-service.sh.template start-text-track-service.sh
cp start-text-track-service-worker.sh.template start-text-track-service-worker.sh
faktory_password=$( cat /etc/faktory/password )
sed -i "s/FAKTORY_PASSWORD/$faktory_password/g" start-text-track-service.sh
sed -i "s/FAKTORY_PASSWORD/$faktory_password/g" start-text-track-service-worker.sh
