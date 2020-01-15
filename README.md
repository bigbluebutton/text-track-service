#### Text-Track-Service is a project to help bigbluebutton auto-generate captions for their videos using multiple paid and free services. This was done to make bigbluebutton more accessible to students and teachers alike.
#### We approached this by giving the user access to multiple services both paid & free to use according to their choosing. Also it is using the faktory queuing system to ensure efficient usage of server resources.
#### The documentation is for BigBlueButton admins that want to set up the text-track-service on a server already running with bigbluebutton to generate captions.
###### You can try it out here:- https://demo.bigbluebutton.org/

Here is a simple diagram of how it works:-
![Text-Track-Service Diagram](diagram-tts.png)

## Before install
Set up rap-caption-inbox (skip set up if you have BigBlueButton 2.3 or later just `sudo systemctl start bbb-rap-caption-inbox.service`)
```
sudo cp rap-caption-inbox.rb /var/bigbluebutton/captions/inbox/rap-caption-inbox.rb (copy file from repo)
cd /var/bigbluebutton/captions/inbox

sudo chown root:root /usr/local/bigbluebutton/core/scripts/rap-caption-inbox.rb
sudo chmod ugo+x /usr/local/bigbluebutton/core/scripts/rap-caption-inbox.rb
sudo systemctl start bbb-rap-caption-inbox.service
```

Steps to test
```
sudo systemctl status bbb-rap-caption-inbox.service
```

## Instructions to set up Text-track-service with IBM (just edit credentials.yaml for other services accordingly - look at example.credentials for reference also Step13.)
---

### 1. Set up texttrack user on the server
Steps to set up
```
adduser texttrack
usermod -aG sudo texttrack
su texttrack (switch to texttrack user)
```
Steps to test
```
sudo ls -la /root
```
---

### 2. Set up docker on the server
Check if you have docker installed
```
docker --version
```

If you don't have docker installed please follow the steps given at https://docs.docker.com/install/linux/docker-ce/ubuntu/ for more information.

Steps to test
```
sudo docker run hello-world
```
---

### 3. Set up docker-compose on the server
Steps to set up
```
Follow instructions at:- https://docs.docker.com/compose/install/
```

Steps to test
```
docker-compose --version
```
---

### 3. Add texttrack user to docker
```
sudo usermod -a -G docker texttrack
```
---

### 4. Create dir & clone github repo
Steps to set up
```
sudo apt update
sudo apt install git
```

Steps to test
```
git --version
```

Clone repo
```
cd /var
sudo mkdir docker
sudo chown texttrack:textrack /var/docker
cd docker
git clone https://github.com/bigbluebutton/text-track-service
cd text-track-service
```
---

### 5. Set up credentials(IBM) & test

The installation instructions are for IBM if you want to use another service visit this link: https://docs.google.com/document/d/e/2PACX-1vQu9o5q1tdf84cPo8kn6vt8QvhyuYJKdhLBVNIeuIHBwpxdRqWu0bmIgHsm8z5dU6YIjoZeDHxwSHu2/pub
Follow instructions for setting up the service you want.

steps to set up:
```
sign up to IBM at: https://dataplatform.cloud.ibm.com/docs/content/wsj/getting-started/signup-wdp.html
After signing in you should be able to see the dashboard.  Click on Watson in the left menu.
Click on get started (convert audio into text) then you can give service name and/or tag name here. And select the blue create button in the right panel.
You can give the service name of your choice. Then click create.
Click on manage in the left panel and you will be able to see your credentials.

Save your apikey & url given.

```

Steps to test (under test_dir there is a test audio_temp.flac to test your credentials with.)
```
once you have your IBM api_key & url open terminal and do the following:
(make sure to replace {apikey} & {url} with your credentials)

cd /var/docker/text-track-service/test_dir

curl -X POST -u "apikey:{apikey}" \
--header "Content-Type: audio/flac" \
--data-binary @audio_temp.flac \
"{url}/v1/recognize"

```
---

### 6. Add your service credentials in credentials.yaml file

Steps to set up
```
cp example-credentials.yaml credentials.yaml
Now edit your information in credentials.yaml (you can refer example-credentials.yaml file in /var/docker/text-track-service)

(extra step for google account)
create auth/google_auth_file.json and add file name to credentials.yaml (make sure google auth file owner is texttrack)
```
---

### 7. Set up systemd files
Steps to set up
```
cd /var/docker/text-track-service/systemd
sudo cp tts-docker.service /etc/systemd/system
sudo systemctl enable tts-docker

sudo chmod -R a+rX /var/docker/text-track-service/tmp/*

sudo systemctl start tts-docker
```

Steps to test
```
sudo journalctl -u tts-docker -f (see tailed logs) (if you are doing it very first time, you will get an error because there is no database. We will set it up in the next step.)
```
---

### 8. Open new terminal to set up new db
Steps to set up
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

Steps to test
```
sudo journalctl -u tts-docker -f (You should no longer get a no db error)
```
---

### 9. Add info to bigbluebutton.yml file on bbb server
```
cd /usr/local/bigbluebutton/core/scripts/

To find your secret: bbb-conf -secret (shared secret)
Set up tts-secret in credentials.yaml and then enter that in /usr/local/bigbluebutton/core/scripts/bigbluebutton.yml

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
sudo apt-get install ffmpeg

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

Text-Track-Service only drops the files in the inbox folder at /var/bigbluebutton/captions/inbox
Now the rap-caption-inbox.rb should move it to the presentation dir(/var/bigbluebutton/published/presentation/<record-id>) to start it run the foll command:
```
sudo systemctl start bbb-rap-caption-inbox.service
sudo systemctl status bbb-rap-caption-inbox.service (Status should be running)
```
---

### 11. Record a meeting and check for vtt
Finally make a recording/meeting on your server
Look at the logs to make sure it processes successfully(sudo journalctl -u tts-docker -f)
Check the presentation folder of the record_id to see if a vtt file was generated. This can be found at (/var/bigbluebutton/published/presentation/<record_id>)
If there is a vtt file you have successfully transcribed your first meeting using IBM.
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
Here is a link to a google docs for signing up to the services: https://docs.google.com/document/d/e/2PACX-1vQu9o5q1tdf84cPo8kn6vt8QvhyuYJKdhLBVNIeuIHBwpxdRqWu0bmIgHsm8z5dU6YIjoZeDHxwSHu2/pub
To use other services you need to edit credentials.yaml file with the details required
Reference example-credentials.yaml for needed information
Finally edit post_publish.rb to use the new selected service as discussed in Step 10.
```
sudo vim /usr/local/bigbluebutton/core/scripts/post_publish/post_publish.rb
On line 113 add ibm or the service you want to (http://localhost:4000/caption/#{meeting_id}/en-US/) to the end of the line eg. http://localhost:4000/caption/#{meeting_id}/en-US/ibm
save & exit
```
To set up your own deepspeech server follow instructions at: https://github.com/bigbluebutton/deepspeech-web

### 14. Install & use api commands for information

Install api commands
```
cd /var/docker/text-track-service/commands
./config.sh (run api config file)
you can now use the commands from anywhere in the terminal as long as you are ssh into the server
```

Api usage
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
