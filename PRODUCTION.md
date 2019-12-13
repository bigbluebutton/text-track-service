Create user texttrack
```
adduser texttrack
usermod -aG sudo texttrack
su texttrack (switch to texttrack user)
sudo ls -la /root
```

Check if you have docker installed
```
#command to check docker version
docker --version
```

If you don't have docker installed please follow the steps given below or go to https://docs.docker.com/install/linux/docker-ce/ubuntu/ for more information.
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

# To install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Create and Add texttrack(user) to docker group
sudo usermod -a -G docker texttrack
```

To verify docker
```
sudo docker run hello-world
```

Create appropriate working dir
```
cd /var
sudo mkdir docker
sudo chown texttrack:textrack /var/docker
cd docker
git clone https://github.com/bigbluebutton/text-track-service
cd text-track-service
```

don't forget to
```
create your credentials file
create auth/google_auth_file and add file name to credentials.yaml (make sure google auth file owner is texttrack)
```

Copy systemd file and start service
```
cd /var/docker/text-track-service/systemd
sudo cp tts-docker.service /etc/systemd/system
sudo systemctl enable tts-docker

sudo chmod -R a+rX /var/docker/text-track-service/tmp/*

sudo systemctl start tts-docker

sudo journalctl -u tts-docker -f (see tailed logs)
```

Setup db after starting application

```
cd /usr/local/text-track-service
# if you are creating first time then use db:create otherwise db:reset
sudo chmod -R a+rX *
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:create

sudo chmod -R a+rX *
sudo docker-compose exec --user "$(id -u):$(id -g)" website rails db:migrate

sudo visudo

Add the following line to the end of the file:
texttrack ALL = NOPASSWD: /var/docker/text-track-service/deploy.sh

./deploy.sh

```

Add some information to bigbluebutton.yml file on bbb server
```
cd /usr/local/bigbluebutton/core/scripts/

To find your secret: bbb-conf -secret
To find tts-secret: tts-secret (first run config.sh in /var/docker/text-track-service/commands)

sudo vim bigbluebutton.yml

presentation_dir: /var/bigbluebutton/published/presentation
shared_secret: secret
temp_storage: /var/bigbluebutton/captions
tts_shared_secret: egUE@#IY@&*h82uioh#EN@H$#*orhdo8234hO@HoH$@ORHF#$*r@W


```

Everything is up and running. Now change post_publish file on bbb server. 
Edit post_publish file(for automatic captions)
```
Navigate to /usr/local/bigbluebutton/core/scripts/post_publish 

sudo gem install rest-client

Insert the following into your post_publish.rb file just below custom script starts here

temp_storage = bbb_props['temp_storage']
final_dest_dir = "#{temp_storage}/#{meeting_id}"
audio_file = "#{meeting_id}.wav"

unless Dir.exist?(final_dest_dir)
  FileUtils.mkdir_p(final_dest_dir)
  FileUtils.chmod('u=wrx,g=wrx,o=r', final_dest_dir)
end

unless File.exist?("#{final_dest_dir}/#{audio_file}")
SpeechToText::Util.video_to_audio(
  video_file_path: "#{published_files}/video",
  video_name: 'webcams',
  video_content_type: 'webm',
  audio_file_path: final_dest_dir.to_s,
  audio_name: meeting_id,
  audio_content_type: "wav"
)
end

site = "http://#{bbb_props['playback_host']}"
secret = bbb_props['shared_secret']
kind = "subtitles"
lang = "en_US"
label = "English"
request = "putRecordingTextTrackrecordID=#{meeting_id}&kind=#{kind}&lang=#{lang}&label=#{label}"
request += secret
checksum = Digest::SHA1.hexdigest(request)

start_time = nil 
end_time = nil 

tts_secret = bbb_props['tts_shared_secret']

payload = { :bbb_url => site, 
            :bbb_checksum => checksum, 
            :kind => kind,
            :label => label,
            :start_time => start_time,
            :end_time => end_time
          }   

token = JWT.encode payload, "#{tts_secret}", 'HS256'

request = RestClient::Request.new(
    method: :get,
    url: "https://ritz-tts6.freddixon.ca/tts/caption/#{meeting_id}/en-US",
    payload: { :file => File.open("#{temp_storage}/#{meeting_id}/#{meeting_id}.wav", 'rb'),
               :token => token }
)

response = request.execute


if(response.code != 200)
  BigBlueButton.logger.info("#{response.code} error")
end

exit 0


now do bbb-conf secret to find your secret
copy that value into /usr/local/bigbluebutton/core/scripts/bigbluebutton.yml as shared_secret: whatever_your_secret_is
```

Some useful commands 
before running commands navigate to /var/docker/text-track-service/commands and run ./config.sh && gem install table_print
```
tts-all #List all the records from database
tts-processed #Get all the processed records
tts-failed #Get failed records

#get information for specific record
tts-record <record_id >
#or
tts-record -r <record_id>

tts-delete-all
tts-delete record_id
```
