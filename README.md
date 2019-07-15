# README

# test-track-service
Service to generate text tracks for BigBlueButton recordings

Redis

Make sure you have Redis installed.

Install [Faktory](https://github.com/contribsys/faktory/wiki/Installation)

```
wget https://github.com/contribsys/faktory/releases/download/v1.0.1-1/faktory_1.0.1-1_amd64.deb

sudo dpkg -i faktory_1.0.1-1_amd64.deb

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
rbenv install 2.6.1
rbenv local 2.6.1
ruby -v

gem install bundler
gem env home
gem install rails -v 5.2.3
rbenv rehash
bundle install

rails db:setup

# Start rails and listen on all interfaces
rails s -b 0.0.0.0

#To test

curl http://<ip>:3000

```

Open terminal 2

```
# Start the service
./development/start-service.sh
```

Open terminal 3

```
# Start the worker
./developemtn/start-worker.sh
```

Open terminal 4

```
# Queue up a recording for processing

curl http://<ip>:3000/service/foo
```