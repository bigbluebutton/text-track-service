## Instructions to set up Text-track-service with IBM (just edit credentials.yaml for other services accordingly - look at example.credentials for reference)
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

### 5. Set up credentials & db

* create & edit credentials.yaml (reference example-credentials.yaml)
```
touch credentials.yaml
```

* extra step for google account
```
create auth/google_auth_file and add file name to credentials.yaml (make sure google auth file owner is texttrack)
```