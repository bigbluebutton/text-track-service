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
mkdir .ssh
cd .ssh
touch authorized_keys
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
```

Give access to texttrack to needed folders
```
sudo chmod g-s,g+x /var/bigbluebutton/captions
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
rbenv local 2.5.3
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

# Edit post_publish file

Navigate to /usr/local/bigbluebutton/core/scripts/post_publish 
```
gem install rest-client
sudo mv post_publish.rb.example post_publish.rb
sudo nano post_publish.rb

add the following code just above exit 0 at the bottom
require "rest-client"

response = RestClient::Request.execute(
    method: :get,
    url:    "http://localhost:4000/caption/#{$meeting_id}/en-US",
)

if(response.code != 200)
  BigBlueButton.logger.info("#{response.code} error")
end

ctrl x type y and hit enter to save and exit

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

