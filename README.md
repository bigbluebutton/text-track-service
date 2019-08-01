# README

# test-track-service
Service to generate text tracks for BigBlueButton recordings

Install [Faktory](https://github.com/contribsys/faktory/wiki/Installation)

```
# Download deb distro for Ubuntu
sudo dpkg -i <filename.deb>

# After installing, find the password
 sudo cat /etc/faktory/password

# Start the worker passing the password
 FAKTORY_PROVIDER=FAKTORY_URL FAKTORY_URL=tcp://:7832525986eee2f7@localhost:7419 bundle exec faktory-worker -r ./app.rb

```

# Insert all api details in info.json in the following format
```
{
  "google":{
    "auth_key" : "json_file",
    "google_bucket_name" : "bucket_name"
  },
  "ibm":{
    "auth_key" : "api_key"
  }
}
```

```
1)Make sure your faktory service is running
2)Make sure faktory workers are running run text-track-worker.rb
(FAKTORY_PROVIDER=FAKTORY_URL FAKTORY_URL=tcp://:7832525986eee2f7@localhost:7419 bundle exec faktory-worker -r ./google-worker.rb)
3)run app.rb
4)Make an http request to either /service/google or /service/ibm to trigger each service. (can also use the view by going to "/" and selecting a service)
...
```

# Instructions for progress updates
```
1) make a request to /progress for all updates
2) make a request to /progress/:recordID for updates of a specific recording
```

# Rails
```
moved all ruby files in ruby_files folder
moved test folder to root as test2 since rails has its own test folder
databse name is development.sqlite3 table name is captions
```

# Country codes for Google

https://cloud.google.com/speech-to-text/docs/languages

# Country codes for Ibm

https://cloud.ibm.com/docs/services/discovery?topic=discovery-language-support

# Country codes for Speechmatics

https://www.speechmatics.com/language-support/