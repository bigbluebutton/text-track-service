#/usr/local/bin/docker-compose -f /var/docker/text-track-service/docker-compose.yml down -v
sudo systemctl stop tts-docker
sudo mv /var/docker/text-track-service/storage/* /var/recording_dir
cd /var/docker/text-track-service
git pull origin docker
sudo -kS chmod -R a+rX *
sudo systemctl start tts-docker
#/usr/local/bin/docker-compose -f /var/docker/text-track-service/docker-compose.yml up --build -d
