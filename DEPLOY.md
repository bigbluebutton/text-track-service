# Deploy text-track service

# First lets create a user with sudo access on the server

ssh into your server
```
adduser texttrack
```

grant sudo access to this user
```
usermod -aG sudo texttrack
```

add your public key to the list of authorized users for this user at /home/texttrack/.ssh/authorized_keys

test sudo access
```
su texttrack (switch to user)
sudo ls -la /root
```

Add public key to texttrack user at /home/texttrack/.ssh/authorized_users
```
cd /home/texttrack
sudo mkdir .ssh
cd .ssh
sudo touch authorized_keys
paste your public key in this file(authorized_keys)
```

# Now install big blue button

Go home by typing cd and hitting enter, then enter the following command
Make sure to replace bbb.example.com with your domain name and info@example.com with your email
```
wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | bash -s -- -v xenial-220-beta -s bbb.example.com -e info@example.com
```

Install the podcast package
```
sudo apt-get install bbb-playback-podcast
```

Visit your domain and start a meeting to see if everything is working okay
```
bbb.example.com/demo/demo10.jsp
```

Add texttrack user to bigbluebutton group
```
cat /etc/group (check groups)
sudo usermod -a -G bigbluebutton texttrack
sudo usermod -a -G texttrack bigbluebutton #######################
```

Add some information to bigbluebutton.yml file
```
cd /usr/local/bigbluebutton/core/scripts/
sudo vim bigbluebutton.yml

presentation_dir: /var/bigbluebutton/published/presentation
shared_secret: secret
temp_storage: /var/bigbluebutton/captions

To find your secret: bbb-conf -secret
```

Give access to texttrack to needed folders
```
sudo chmod g+wrx /var/bigbluebutton/captions
sudo chmod g+wrx /var/bigbluebutton/captions/inbox
```

Create temp folder for storage at /var/texttrackservice and give permissions
```
cd /var
sudo mkdir texttrackservice
sudo chown -R texttrack:texttrack /var/texttrackservice (change ownership to texttrackservice)
sudo chmod g+w /var/texttrackservice/ (give group permissions)
```

# Install text-track-service rails app

Navigate to /usr/local/
```
sudo git clone https://github.com/bigbluebutton/text-track-service.git
```

Install [Faktory](https://github.com/contribsys/faktory/wiki/Installation)

```
cd text-track-service
sudo wget https://github.com/contribsys/faktory/releases/download/v1.0.1-1/faktory_1.0.1-1_amd64.deb

sudo dpkg -i faktory_1.0.1-1_amd64.deb

sudo cat /etc/faktory/password (Manually find password if ever needed)

```

Development

You will need to open at least 4 terminal windows: (1) for rails app,
(2) for text-track service, (3) for text-track-worker, (4) for commands you issue

Open terminal 1

```
cd development

# Configure start scripts. This will get the Faktory password and set it in start-server.sh
# and start-worker.sh
sudo ./setup.sh

```

Starting the Rails app

Setup Rails

```
sudo apt install build-essential
sudo apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev

# Needed for rake db:setup
sudo apt install nodejs
sudo apt install npm

# setup rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
sudo apt-get install -y libssl-dev libreadline-dev
rbenv install 2.5.3
sudo chown -R texttrack.texttrack ~/.rbenv
rbenv local 2.5.3 ######################### rbenv rbenv global 2.5.3
ruby -v

gem install bundler
gem env home
gem install rails -v 5.2.3
rbenv rehash
sudo apt-get install libsqlite3-dev
sudo chown -R texttrack:texttrack /usr/local/text-track-service
bundle install

rails db:setup

# If Ruby & permission issues
sudo chown -R texttrack.texttrack ~/.rbenv
sudo chown -R texttrack:texttrack /usr/local/text-track-service

# Start rails on port 4000
rails s -p 4000

#To test

curl http://<ip>:4000

```

Open terminal 2

```
# Copy example-credentials.yaml to credentials.yaml
cd /usr/local/text-track-service
cp example-credentials.yaml credentials.yaml

Also copy your google auth json file into a folder called auth inside the app folder if you plan on using google translate

# Edit credentials.yaml to setup your credentials for the providers.

# Start the service
./development/start-service.sh

Make an http request to either /service/google/recordID/language or /service/ibm to trigger each service. (can also use the view by going to "/" and selecting a service)
eg. /service/google/french-test/fr-FR
...
```

Open terminal 3

```
# Start the worker
./developement/start-worker.sh
```

Start a recording & Open terminal 4 to watch the progress of the recording

```
bbb-record --watch
```

After it is done reload the demo page and click on presentation, you should have a video with captions
```
navigate to the record id folder at /var/bigbluebutton/captions/inbox/ to see the captions.json and vtt files
```

# Copy /usr/local/text-track-service/service/*.service to /etc/systemd/system
```
cd /usr/local/text-track-service/service/
sudo cp *.service /etc/systemd/system
```

# Start all services (make sure faktory password in the files is correct)
```
sudo systemctl enable text-track-rails
sudo systemctl start text-track-rails

sudo systemctl enable text-track-service
sudo systemctl start text-track-service

sudo systemctl enable text-track-worker
sudo systemctl start text-track-worker
```

# If restart or stop service 
```
sudo systemctl restart service-name
sudo systemctl stop service-name
```

# If Check service
```
sudo systemctl status service-name
```

# easy edit service file for future
```
sudo systemctl edit service-name --full
sudo systemctl daemon-reload (After editing)
sudo journalctl -u service-name.service
```

# see logs for service
```
sudo journalctl -u service-name.service
```

# clear journals
```
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s
```

# Edit post_publish file(for automatic captions)
```
Navigate to /usr/local/bigbluebutton/core/scripts/post_publish 

sudo gem install rest-client
sudo cp /usr/local/text-track-service/post_publish.rb /usr/local/bigbluebutton/core/scripts/post_publish

now do bbb-conf secret to find your secret
copy that value into /usr/local/bigbluebutton/core/scripts/bigbluebutton.yml as shared_secret: whatever_your_secret_is

```

# 

# If you make any changes to the code please run & keep code clean with Rubocop
```
rubocop --safe-auto-correct --disable-uncorrectable
```

# Docker side changes
Install docker & docker-compose
```
sudo apt-get update
sudo apt-get remove docker docker-engine docker.io
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
docker --version

sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
docker ps (to check if anything is running nothing should be)
add texttrack to docker group via sudo usermod -a -G docker texttrack
```

Create appropriate dir
```
cd /var
sudo mkdir docker
sudo chown texttrack:textrack /var/docker
cd docker
git clone -b docker https://github.com/SilentFlameCR/text-track-service
cd text-track-service
```

don't forget to
```
create your credentials file
create auth/google_auth_file and add file name to settings.yml
```

Create private/public key and encrypt on the computer your developing from (NOT SERVER - ONLY FOR CI CD)
```
cd /var/docker/text-track-service
ssh-keygen -f deploy_key
add the private key inside deploy_key.pub to the authorized keys on the server (This enables travis-ci to ssh into the server for ci cd)
travis encrypt-file deploy_key --add
sudo mv deploy_file deploy_file.pub ..
```

Add to sudoers file(Again for CI CD)
```
sudo visudo

Add the following line to the end of the file:
texttrack ALL = NOPASSWD: /var/docker/text-track-service/deploy.sh
```

Setup db
```
cd /var/docker/text-track-service
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:reset
cd /var/docker/text-track-service/db
sudo chmod -R a+rX *
sudo chmod ugo+rwx /var/docker/text-track-service/log/
cd /var/docker/text-track-service/log/
mkdir development.log
sudo chmod ugo+rwx /var/docker/text-track-service/log/development.log
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:migrate
sudo service docker restart
```

Move and start systemctl files
```
cd /var/docker/text-track-service/systemd
sudo cp tts-docker.service /etc/systemd/system
sudo systemctl enable tts-docker
sudo systemctl start tts-docker

sudo chmod -R a+rX /var/docker/text-track-service/tmp/*

sudo journalctl -u tts-docker -f (see tailed logs)
```














































































