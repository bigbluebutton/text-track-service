Text-Track-Service is a project to help bigbluebutton auto-generate captions for their videos using multiple paid and free services. This was done to make bigbluebutton more accessible to students and teachers alike.
We approached this by giving the user access to multiple services both paid & free to use according to their choosing. Also it is using the faktory queuing system to ensure efficient usage of server resources.
The documentation below will cover how to set up the text-track-service on a server already running with bigbluebutton version 2.3
You can try it out here:- https://demo.bigbluebutton.org/demo/demo10.jsp

## Instructions to set up Text-track-service with IBM (just edit credentials.yaml for other services accordingly - look at example.credentials for reference also Step13.)
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
    * here is a link to a google docs for signing up to the services: https://docs.google.com/document/d/e/2PACX-1vQu9o5q1tdf84cPo8kn6vt8QvhyuYJKdhLBVNIeuIHBwpxdRqWu0bmIgHsm8z5dU6YIjoZeDHxwSHu2/pub

* create & edit credentials.yaml (reference example-credentials.yaml)
```
touch credentials.yaml
```

### Add your service credentials in credentials.yaml file

* you can refer example-credentials.yaml file in /var/docker/text-track-service

* extra step for google account
```
create auth/google_auth_file.json and add file name to credentials.yaml (make sure google auth file owner is texttrack)
```
---

### 6. Test your IBM credentials

under test_dir there is a test audio_temp.flac to test your  credentials with.

once you have your IBM api_key & url open terminal and do the following:
(make sure to replace {apikey} & {url} with your credentials)
```
cd /var/docker/text-track-service/test_dir

curl -X POST -u "apikey:{apikey}" \
--header "Content-Type: audio/flac" \
--data-binary @audio_temp.flac \
"{url}/v1/recognize"
```
---

### 7. Set up systemd files
```
cd /var/docker/text-track-service/systemd
sudo cp tts-docker.service /etc/systemd/system
sudo systemctl enable tts-docker

sudo chmod -R a+rX /var/docker/text-track-service/tmp/*

sudo systemctl start tts-docker

sudo journalctl -u tts-docker -f (see tailed logs) (if you are doing it very first time, you will get an error because there is no database. Don't worry about databse error)
```
---

### 8. Open new terminal to set up new db
```
cd /var/docker/text-track-service
sudo rm -R tmp/db

sudo chmod -R a+rX tmp/*
sudo chmod -R a+rX *
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:create

sudo chmod -R a+rX tmp/*
sudo chmod -R a+rX *
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:migrate


sudo visudo
* Add the following line to the end of the file:
texttrack ALL = NOPASSWD: /var/docker/text-track-service/deploy.sh
* save and close the file

 ./deploy.sh
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
tts_shared_secret: {tts-secret}

```
---

### 10. Edit post_publish.rb & start rap-caption-inbox worker
```
cd /usr/local/bigbluebutton/core/scripts/post_publish/

Make sure you have ffmpeg installed:


sudo gem install rest-client
sudo gem install speech_to_text
sudo gem install jwt

(Replace your post_publish.rb with the one in /var/docker/text-track-service)
sudo cp /var/docker/text-track-service/post_publish.rb root@your_server:/usr/local/bigbluebutton/core/scripts/post_publish  (use if bbb and text-track-service are running on different server)
sudo cp /var/docker/text-track-service/post_publish.rb /usr/local/bigbluebutton/core/scripts/post_publish  (use if bbb and text-track-service are running on same server)
```

To change the service you are using in post_publish.rb just add service name to the end of the request url(deepspeech is default)
```
request = RestClient::Request.new(
    method: :get,
    url: "http://localhost:4000/caption/#{meeting_id}/en-US/",
    payload: { :file => File.open("#{temp_storage}/#{meeting_id}/#{meeting_id}.wav", 'rb'),
               :token => token }
)

eg. http://localhost:4000/caption/#{meeting_id}/en-US/google
eg. http://localhost:4000/caption/#{meeting_id}/en-US/ibm
eg. http://localhost:4000/caption/#{meeting_id}/en-US/speechmatics
eg. http://localhost:4000/caption/#{meeting_id}/en-US/threeplaymedia
eg. http://localhost:4000/caption/#{meeting_id}/en-US/deepspeech or http://localhost:4000/caption/#{meeting_id}/en-US/ (deepspeech is default)
```

As we discussed text-track-service only drops the files in the inbox folder at /var/bigbluebutton/captions/inbox
Now the rap-caption-inbox.rb should move it to the presentation dir(/var/bigbluebutton/published/presentation/<record-id>) to start it run the foll command:
```
sudo systemctl start bbb-rap-caption-inbox.service
sudo systemctl status bbb-rap-caption-inbox.service (Status should be running)
```
---

### 11. Record a meeting and check for vtt
* Finally make a recording/meeting on your server
* Look at the logs to make sure it processes successfully(sudo journalctl -u tts-docker -f)
* Check the presentation folder of the record_id to see if a vtt file was generated
    * This can be found at (/var/bigbluebutton/published/presentation/<record_id>)
* If there is a vtt file you have successfully transcribed your first meeting using IBM.
---

### 12. Troubleshooting
If you followed Step 7 your should be able to see tailed logs with the following command
```
sudo journalctl -u tts-docker -f

fix any errors shown and then re-deploy by running deploy.sh in the root folder
```

* If the logs do not show any errors but you are missing the vtt file in the presentation folder check the inbox folder at /var/bigbluebutton/captions/inbox/ (You should see a json and txt file.)
* This means that the text track has done its job and the rap caption worker is not moving the files to the right location.
* To fix this you can copy the rap-caption-inbox.rb file from the repo to your bbb server at /usr/local/bigbluebutton/core/scripts/ & make sure the owner is root.
* Last step is make sure the rap-caption-work.rb has correct execute permissions if not just run the following command:
```
sudo chmod ugo+x /usr/local/bigbluebutton/core/scripts/rap-caption-inbox.rb
sudo systemctl start bbb-rap-caption-inbox.service
```
---

### 13. Other services
* here is a link to a google docs for signing up to the services: https://docs.google.com/document/d/e/2PACX-1vQu9o5q1tdf84cPo8kn6vt8QvhyuYJKdhLBVNIeuIHBwpxdRqWu0bmIgHsm8z5dU6YIjoZeDHxwSHu2/pub
* To use other services you need to edit credentials.yaml file with the details required
* reference example-credentials.yaml for needed information
* Finally edit post_publish.rb to use the new selected service
```
sudo vim /usr/local/bigbluebutton/core/scripts/post_publish/post_publish.rb
On line 113 replace ibm with the service you want or delete ibm without replacing for deepspeech as that is default
save & exit
```
* To set up your own deepspeech server follow instructions at: https://github.com/bigbluebutton/deepspeech-web

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
