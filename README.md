## Instructions to set up Text-track-service with IBM (just edit credentials.yaml for other services accordingly - look at example.credentials for reference also Step12.)
---

### 1. Set up texttrack user on the server
```
adduser texttrack
usermod -aG sudo texttrack
su texttrack (switch to texttrack user)
sudo ls -la /root
```
---

### 2. Set up docker on the server
* Check if you have docker installed
```
docker --version
```
* If you don't have docker installed please follow the steps given below or go to https://docs.docker.com/install/linux/docker-ce/ubuntu/ for more information.
```
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo docker run hello-world
```
---

### 3. Set up docker-compose on the server
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```
---

### 3. Add texttrack user to docker
```
sudo usermod -a -G docker texttrack
```
---

### 4. Create dir & clone github repo
```
cd /var
sudo mkdir docker
sudo chown texttrack:textrack /var/docker
cd docker
git clone https://github.com/bigbluebutton/text-track-service
cd text-track-service
```
---

### 5. Set up credentials(IBM)

* sign up IBM
`-`-`-`-`-`-`-`-`

* create & edit credentials.yaml (reference example-credentials.yaml)
```
touch credentials.yaml
```

* extra step for google account
```
create auth/google_auth_file and add file name to credentials.yaml (make sure google auth file owner is texttrack)
```
---

### 6. Test your IBM credentials

under captions_test dir there is a test audio file called abc.wav

`-`-`-`-`-`-`
---

### 7. Set up systemd files
```
cd /var/docker/text-track-service/systemd
sudo cp tts-docker.service /etc/systemd/system
sudo systemctl enable tts-docker

sudo chmod -R a+rX /var/docker/text-track-service/tmp/*

sudo systemctl start tts-docker

sudo journalctl -u tts-docker -f (see tailed logs)
```
---

### 8. Open new terminal to set up new db
```
cd /usr/local/text-track-service
sudo rm -R tmp/db

sudo chmod -R a+rX *
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:create

sudo chmod -R a+rX *
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:migrate


* sudo visudo
* Add the following line to the end of the file:
texttrack ALL = NOPASSWD: /var/docker/text-track-service/deploy.sh
* ./deploy.sh
```
---

### 9. Add info to bigbluebutton.yml file on bbb server
```
cd /usr/local/bigbluebutton/core/scripts/

To find your secret: bbb-conf -secret
To find tts-secret: tts-secret (first run config.sh in /var/docker/text-track-service/commands)

sudo vim bigbluebutton.yml

presentation_dir: /var/bigbluebutton/published/presentation
shared_secret: secret
temp_storage: /var/bigbluebutton/captions
tts_shared_secret: egUE@IY@&*h82uiohEN@H$*orhdo8234hO@HoH$@ORHF$*r@W


```
---

### 10. Edit post_publish.rb
```
cd /usr/local/bigbluebutton/core/scripts/post_publish/

sudo gem install rest-client
sudo gem install speech_to_text
sudo gem install jwt

(Replace your post_publish.rb with the one in /var/docker/text-track-service)
sudo cp post_publish.rb root@your_server:/usr/local/bigbluebutton/core/scripts/post_publish

```
---

### 11. Record a meeting and check for vtt
* Finally make a recording/meeting on your server
* Look at the logs to make sure it processes successfully(sudo journalctl -u tts-docker -f)
* Check the presentation folder of the record_id to see if a vtt file was generated
    * This can be found at (/var/bigbluebutton/published/presentation/<record_id>)
* If there is a vtt file you have successfully transcribed your first meeting using IBM.

### 12. Troubleshooting
If you followed Step 7 your should be able to see tailed logs with the following command
```
sudo journalctl -u tts-docker -f

fix any errors shown and then re-deploy by running deploy.sh in the root folder
```
---

### 13. Other services
* To use other services you need to edit credentials.yaml file with the details required
* reference example-credentials.yaml for needed information
* Finally edit post_publish.rb to use the new selected service
```
sudo vim /usr/local/bigbluebutton/core/scripts/post_publish/post_publish.rb
On line 113 replace ibm with the service you want or delete ibm without replacing for deepspeech as that is default
save & exit
```

### 14. Install & use api commands for information

* Install api commands
```
cd /var/docker/text-track-service/commands
./config.sh (run api config file)
you can now use the commands from anywhere in the terminal as long as you are ssh into the server
```

* Api usage
```
| Command                 | Result                                                          |
| ----------------------- | --------------------------------------------------------------- |
| tts-all                 | shows list of all record-ids sent to the text-track-service     |
| tts-processed           | list of all successfully processed record-ids                   |
| tts-failed              | list of all failed to process record-ids                        |
| tts-record <record_id>  | get data for specific record_id                                 |
| tts-delete <record_id>  | delete data about a specific recording from text-track-service  |
| tts-delete-all          | delete all data about recordings from text-track-service        |
```
