#/usr/local/bin/docker-compose -f /var/docker/text-track-service/docker-compose.yml down -v
#sudo systemctl stop tts-docker
sudo docker-compose down
ruby commands/move_files.rb
cd /var/docker/text-track-service
git pull origin docker
sudo -kS chmod -R a+rX *
sudo docker-compose up --build
#sudo systemctl start tts-docker
#/usr/local/bin/docker-compose -f /var/docker/text-track-service/docker-compose.yml up --build -d
