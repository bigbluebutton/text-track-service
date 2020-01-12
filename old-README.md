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
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 2.6.1
rbenv local 2.6.1
ruby -v

gem install bundler
gem env home
gem install rails -v 5.2.3
rbenv rehash
apt-get install libsqlite3-dev
bundle install

rails db:setup

# If Ruby & permission issues
sudo chown -R texttrack.texttrack ~/.rbenv
sudo chown -R texttrack:texttrack /usr/local/text-track-service

# Start rails and listen on all interfaces
rails s -b 0.0.0.0

#To test

curl http://<ip>:3000

```

Open terminal 2

```
# Copy example-credentials.yaml to credentials.yaml
cp example-credentials.yaml credentials.yaml

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

Open terminal 4

```
# Queue up a recording for processing

curl http://<ip>:3000/service/foo
```

```

# Country codes for languages (Ibm)

|Language|Broadband model|Narrowband model|
|--- |--- |--- |
|Brazilian Portuguese|pt-BR_BroadbandModel|pt-BR_NarrowbandModel|
|French|fr-FR_BroadbandModel|fr-FR_NarrowbandModel|
|German|de-DE_BroadbandModel|de-DE_NarrowbandModel|
|Japanese|ja-JP_BroadbandModel|ja-JP_NarrowbandModel|
|Korean|ko-KR_BroadbandModel|ko-KR_NarrowbandModel|
|Mandarin Chinese|zh-CN_BroadbandModel|zh-CN_NarrowbandModel|
|Modern Standard Arabic|ar-AR_BroadbandModel|Not supported|
|Spanish|es-ES_BroadbandModel|es-ES_NarrowbandModel|
|UK English|en-GB_BroadbandModel|en-GB_NarrowbandModel|
|US English|en-US_BroadbandModel|en-US_NarrowbandModel|

# Country codes for languages (Google)

|Language|languageCode|Language (English name)|
|--- |--- |--- |
|Afrikaans (Suid-Afrika)|af-ZA|Afrikaans (South Africa)|
|አማርኛ (ኢትዮጵያ)|am-ET|Amharic (Ethiopia)|
|Հայ (Հայաստան)|hy-AM|Armenian (Armenia)|
|Azərbaycan (Azərbaycan)|az-AZ|Azerbaijani (Azerbaijan)|
|Bahasa Indonesia (Indonesia)|id-ID|Indonesian (Indonesia)|
|Bahasa Melayu (Malaysia)|ms-MY|Malay (Malaysia)|
|বাংলা (বাংলাদেশ)|bn-BD|Bengali (Bangladesh)|
|বাংলা (ভারত)|bn-IN|Bengali (India)|
|Català (Espanya)|ca-ES|Catalan (Spain)|
|Čeština (Česká republika)|cs-CZ|Czech (Czech Republic)|
|Dansk (Danmark)|da-DK|Danish (Denmark)|
|Deutsch (Deutschland)|de-DE|German (Germany)|
|English (Australia)|en-AU|English (Australia)|
|English (Canada)|en-CA|English (Canada)|
|English (Ghana)|en-GH|English (Ghana)|
|English (Great Britain)|en-GB|English (United Kingdom)|
|English (India)|en-IN|English (India)|
|English (Ireland)|en-IE|English (Ireland)|
|English (Kenya)|en-KE|English (Kenya)|
|English (New Zealand)|en-NZ|English (New Zealand)|
|English (Nigeria)|en-NG|English (Nigeria)|
|English (Philippines)|en-PH|English (Philippines)|
|English (Singapore)|en-SG|English (Singapore)|
|English (South Africa)|en-ZA|English (South Africa)|
|English (Tanzania)|en-TZ|English (Tanzania)|
|English (United States)|en-US|English (United States)|
|Español (Argentina)|es-AR|Spanish (Argentina)|
|Español (Bolivia)|es-BO|Spanish (Bolivia)|
|Español (Chile)|es-CL|Spanish (Chile)|
|Español (Colombia)|es-CO|Spanish (Colombia)|
|Español (Costa Rica)|es-CR|Spanish (Costa Rica)|
|Español (Ecuador)|es-EC|Spanish (Ecuador)|
|Español (El Salvador)|es-SV|Spanish (El Salvador)|
|Español (España)|es-ES|Spanish (Spain)|
|Español (Estados Unidos)|es-US|Spanish (United States)|
|Español (Guatemala)|es-GT|Spanish (Guatemala)|
|Español (Honduras)|es-HN|Spanish (Honduras)|
|Español (México)|es-MX|Spanish (Mexico)|
|Español (Nicaragua)|es-NI|Spanish (Nicaragua)|
|Español (Panamá)|es-PA|Spanish (Panama)|
|Español (Paraguay)|es-PY|Spanish (Paraguay)|
|Español (Perú)|es-PE|Spanish (Peru)|
|Español (Puerto Rico)|es-PR|Spanish (Puerto Rico)|
|Español (República Dominicana)|es-DO|Spanish (Dominican Republic)|
|Español (Uruguay)|es-UY|Spanish (Uruguay)|
|Español (Venezuela)|es-VE|Spanish (Venezuela)|
|Euskara (Espainia)|eu-ES|Basque (Spain)|
|Filipino (Pilipinas)|fil-PH|Filipino (Philippines)|
|Français (Canada)|fr-CA|French (Canada)|
|Français (France)|fr-FR|French (France)|
|Galego (España)|gl-ES|Galician (Spain)|
|ქართული (საქართველო)|ka-GE|Georgian (Georgia)|
|ગુજરાતી (ભારત)|gu-IN|Gujarati (India)|
|Hrvatski (Hrvatska)|hr-HR|Croatian (Croatia)|
|IsiZulu (Ningizimu Afrika)|zu-ZA|Zulu (South Africa)|
|Íslenska (Ísland)|is-IS|Icelandic (Iceland)|
|Italiano (Italia)|it-IT|Italian (Italy)|
|Jawa (Indonesia)|jv-ID|Javanese (Indonesia)|
|ಕನ್ನಡ (ಭಾರತ)|kn-IN|Kannada (India)|
|ភាសាខ្មែរ (កម្ពុជា)|km-KH|Khmer (Cambodia)|
|ລາວ (ລາວ)|lo-LA|Lao (Laos)|
|Latviešu (latviešu)|lv-LV|Latvian (Latvia)|
|Lietuvių (Lietuva)|lt-LT|Lithuanian (Lithuania)|
|Magyar (Magyarország)|hu-HU|Hungarian (Hungary)|
|മലയാളം (ഇന്ത്യ)|ml-IN|Malayalam (India)|
|मराठी (भारत)|mr-IN|Marathi (India)|
|Nederlands (Nederland)|nl-NL|Dutch (Netherlands)|
|नेपाली (नेपाल)|ne-NP|Nepali (Nepal)|
|Norsk bokmål (Norge)|nb-NO|Norwegian Bokmål (Norway)|
|Polski (Polska)|pl-PL|Polish (Poland)|
|Português (Brasil)|pt-BR|Portuguese (Brazil)|
|Português (Portugal)|pt-PT|Portuguese (Portugal)|
|Română (România)|ro-RO|Romanian (Romania)|
|සිංහල (ශ්රී ලංකාව)|si-LK|Sinhala (Sri Lanka)|
|Slovenčina (Slovensko)|sk-SK|Slovak (Slovakia)|
|Slovenščina (Slovenija)|sl-SI|Slovenian (Slovenia)|
|Urang (Indonesia)|su-ID|Sundanese (Indonesia)|
|Swahili (Tanzania)|sw-TZ|Swahili (Tanzania)|
|Swahili (Kenya)|sw-KE|Swahili (Kenya)|
|Suomi (Suomi)|fi-FI|Finnish (Finland)|
|Svenska (Sverige)|sv-SE|Swedish (Sweden)|
|தமிழ் (இந்தியா)|ta-IN|Tamil (India)|
|தமிழ் (சிங்கப்பூர்)|ta-SG|Tamil (Singapore)|
|தமிழ் (இலங்கை)|ta-LK|Tamil (Sri Lanka)|
|தமிழ் (மலேசியா)|ta-MY|Tamil (Malaysia)|
|తెలుగు (భారతదేశం)|te-IN|Telugu (India)|
|Tiếng Việt (Việt Nam)|vi-VN|Vietnamese (Vietnam)|
|Türkçe (Türkiye)|tr-TR|Turkish (Turkey)|
|اردو (پاکستان)|ur-PK|Urdu (Pakistan)|
|اردو (بھارت)|ur-IN|Urdu (India)|
|Ελληνικά (Ελλάδα)|el-GR|Greek (Greece)|
|Български (България)|bg-BG|Bulgarian (Bulgaria)|
|Русский (Россия)|ru-RU|Russian (Russia)|
|Српски (Србија)|sr-RS|Serbian (Serbia)|
|Українська (Україна)|uk-UA|Ukrainian (Ukraine)|
|עברית (ישראל)|he-IL|Hebrew (Israel)|
|العربية (إسرائيل)|ar-IL|Arabic (Israel)|
|العربية (الأردن)|ar-JO|Arabic (Jordan)|
|العربية (الإمارات)|ar-AE|Arabic (United Arab Emirates)|
|العربية (البحرين)|ar-BH|Arabic (Bahrain)|
|العربية (الجزائر)|ar-DZ|Arabic (Algeria)|
|العربية (السعودية)|ar-SA|Arabic (Saudi Arabia)|
|العربية (العراق)|ar-IQ|Arabic (Iraq)|
|العربية (الكويت)|ar-KW|Arabic (Kuwait)|
|العربية (المغرب)|ar-MA|Arabic (Morocco)|
|العربية (تونس)|ar-TN|Arabic (Tunisia)|
|العربية (عُمان)|ar-OM|Arabic (Oman)|
|العربية (فلسطين)|ar-PS|Arabic (State of Palestine)|
|العربية (قطر)|ar-QA|Arabic (Qatar)|
|العربية (لبنان)|ar-LB|Arabic (Lebanon)|
|العربية (مصر)|ar-EG|Arabic (Egypt)|
|فارسی (ایران)|fa-IR|Persian (Iran)|
|हिन्दी (भारत)|hi-IN|Hindi (India)|
|ไทย (ประเทศไทย)|th-TH|Thai (Thailand)|
|한국어 (대한민국)|ko-KR|Korean (South Korea)|
|國語 (台灣)|zh-TW|Chinese, Mandarin (Traditional, Taiwan)|
|廣東話 (香港)|yue-Hant-HK|Chinese, Cantonese (Traditional, Hong Kong)|
|日本語（日本）|ja-JP|Japanese (Japan)|
|普通話 (香港)|zh-HK|Chinese, Mandarin (Simplified, Hong Kong)|
|普通话 (中国大陆)|zh|Chinese, Mandarin (Simplified, China)|


# Country codes for Speechmatics

https://www.speechmatics.com/language-support/
