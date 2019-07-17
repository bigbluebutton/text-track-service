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
4)Make an http request to either /service/google/recordID/language or /service/ibm to trigger each service. (can also use the view by going to "/" and selecting a service)
eg. /service/google/french-test/fr-FR
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

# Country codes for languages
```
<table>
<thead>
<tr>
<th style="text-align: left">Language</th>
<th style="text-align: left"><code>languageCode</code></th>
<th style="text-align: left">Language (English name)</th>
</tr>
</thead>

<tbody>
<tr>
<td style="text-align: left">Afrikaans (Suid-Afrika)</td>
<td style="text-align: left">af-ZA</td>
<td style="text-align: left">Afrikaans (South Africa)</td>
</tr>
<tr>
<td style="text-align: left">አማርኛ (ኢትዮጵያ)</td>
<td style="text-align: left">am-ET</td>
<td style="text-align: left">Amharic (Ethiopia)</td>
</tr>
<tr>
<td style="text-align: left">Հայ (Հայաստան)</td>
<td style="text-align: left">hy-AM</td>
<td style="text-align: left">Armenian (Armenia)</td>
</tr>
<tr>
<td style="text-align: left">Azərbaycan (Azərbaycan)</td>
<td style="text-align: left">az-AZ</td>
<td style="text-align: left">Azerbaijani (Azerbaijan)</td>
</tr>
<tr>
<td style="text-align: left">Bahasa Indonesia (Indonesia)</td>
<td style="text-align: left">id-ID</td>
<td style="text-align: left">Indonesian (Indonesia)</td>
</tr>
<tr>
<td style="text-align: left">Bahasa Melayu (Malaysia)</td>
<td style="text-align: left">ms-MY</td>
<td style="text-align: left">Malay (Malaysia)</td>
</tr>
<tr>
<td style="text-align: left">বাংলা (বাংলাদেশ)</td>
<td style="text-align: left">bn-BD</td>
<td style="text-align: left">Bengali (Bangladesh)</td>
</tr>
<tr>
<td style="text-align: left">বাংলা (ভারত)</td>
<td style="text-align: left">bn-IN</td>
<td style="text-align: left">Bengali (India)</td>
</tr>
<tr>
<td style="text-align: left">Català (Espanya)</td>
<td style="text-align: left">ca-ES</td>
<td style="text-align: left">Catalan (Spain)</td>
</tr>
<tr>
<td style="text-align: left">Čeština (Česká republika)</td>
<td style="text-align: left">cs-CZ</td>
<td style="text-align: left">Czech (Czech Republic)</td>
</tr>
<tr>
<td style="text-align: left">Dansk (Danmark)</td>
<td style="text-align: left">da-DK</td>
<td style="text-align: left">Danish (Denmark)</td>
</tr>
<tr>
<td style="text-align: left">Deutsch (Deutschland)</td>
<td style="text-align: left">de-DE</td>
<td style="text-align: left">German (Germany)</td>
</tr>
<tr>
<td style="text-align: left">English (Australia)</td>
<td style="text-align: left">en-AU</td>
<td style="text-align: left">English (Australia)</td>
</tr>
<tr>
<td style="text-align: left">English (Canada)</td>
<td style="text-align: left">en-CA</td>
<td style="text-align: left">English (Canada)</td>
</tr>
<tr>
<td style="text-align: left">English (Ghana)</td>
<td style="text-align: left">en-GH</td>
<td style="text-align: left">English (Ghana)</td>
</tr>
<tr>
<td style="text-align: left">English (Great Britain)</td>
<td style="text-align: left">en-GB</td>
<td style="text-align: left">English (United Kingdom)</td>
</tr>
<tr>
<td style="text-align: left">English (India)</td>
<td style="text-align: left">en-IN</td>
<td style="text-align: left">English (India)</td>
</tr>
<tr>
<td style="text-align: left">English (Ireland)</td>
<td style="text-align: left">en-IE</td>
<td style="text-align: left">English (Ireland)</td>
</tr>
<tr>
<td style="text-align: left">English (Kenya)</td>
<td style="text-align: left">en-KE</td>
<td style="text-align: left">English (Kenya)</td>
</tr>
<tr>
<td style="text-align: left">English (New Zealand)</td>
<td style="text-align: left">en-NZ</td>
<td style="text-align: left">English (New Zealand)</td>
</tr>
<tr>
<td style="text-align: left">English (Nigeria)</td>
<td style="text-align: left">en-NG</td>
<td style="text-align: left">English (Nigeria)</td>
</tr>
<tr>
<td style="text-align: left">English (Philippines)</td>
<td style="text-align: left">en-PH</td>
<td style="text-align: left">English (Philippines)</td>
</tr>
<tr>
<td style="text-align: left">English (Singapore)</td>
<td style="text-align: left">en-SG</td>
<td style="text-align: left">English (Singapore)</td>
</tr>
<tr>
<td style="text-align: left">English (South Africa)</td>
<td style="text-align: left">en-ZA</td>
<td style="text-align: left">English (South Africa)</td>
</tr>
<tr>
<td style="text-align: left">English (Tanzania)</td>
<td style="text-align: left">en-TZ</td>
<td style="text-align: left">English (Tanzania)</td>
</tr>
<tr>
<td style="text-align: left">English (United States)</td>
<td style="text-align: left">en-US</td>
<td style="text-align: left">English (United States)</td>
</tr>
<tr>
<td style="text-align: left">Español (Argentina)</td>
<td style="text-align: left">es-AR</td>
<td style="text-align: left">Spanish (Argentina)</td>
</tr>
<tr>
<td style="text-align: left">Español (Bolivia)</td>
<td style="text-align: left">es-BO</td>
<td style="text-align: left">Spanish (Bolivia)</td>
</tr>
<tr>
<td style="text-align: left">Español (Chile)</td>
<td style="text-align: left">es-CL</td>
<td style="text-align: left">Spanish (Chile)</td>
</tr>
<tr>
<td style="text-align: left">Español (Colombia)</td>
<td style="text-align: left">es-CO</td>
<td style="text-align: left">Spanish (Colombia)</td>
</tr>
<tr>
<td style="text-align: left">Español (Costa Rica)</td>
<td style="text-align: left">es-CR</td>
<td style="text-align: left">Spanish (Costa Rica)</td>
</tr>
<tr>
<td style="text-align: left">Español (Ecuador)</td>
<td style="text-align: left">es-EC</td>
<td style="text-align: left">Spanish (Ecuador)</td>
</tr>
<tr>
<td style="text-align: left">Español (El Salvador)</td>
<td style="text-align: left">es-SV</td>
<td style="text-align: left">Spanish (El Salvador)</td>
</tr>
<tr>
<td style="text-align: left">Español (España)</td>
<td style="text-align: left">es-ES</td>
<td style="text-align: left">Spanish (Spain)</td>
</tr>
<tr>
<td style="text-align: left">Español (Estados Unidos)</td>
<td style="text-align: left">es-US</td>
<td style="text-align: left">Spanish (United States)</td>
</tr>
<tr>
<td style="text-align: left">Español (Guatemala)</td>
<td style="text-align: left">es-GT</td>
<td style="text-align: left">Spanish (Guatemala)</td>
</tr>
<tr>
<td style="text-align: left">Español (Honduras)</td>
<td style="text-align: left">es-HN</td>
<td style="text-align: left">Spanish (Honduras)</td>
</tr>
<tr>
<td style="text-align: left">Español (México)</td>
<td style="text-align: left">es-MX</td>
<td style="text-align: left">Spanish (Mexico)</td>
</tr>
<tr>
<td style="text-align: left">Español (Nicaragua)</td>
<td style="text-align: left">es-NI</td>
<td style="text-align: left">Spanish (Nicaragua)</td>
</tr>
<tr>
<td style="text-align: left">Español (Panamá)</td>
<td style="text-align: left">es-PA</td>
<td style="text-align: left">Spanish (Panama)</td>
</tr>
<tr>
<td style="text-align: left">Español (Paraguay)</td>
<td style="text-align: left">es-PY</td>
<td style="text-align: left">Spanish (Paraguay)</td>
</tr>
<tr>
<td style="text-align: left">Español (Perú)</td>
<td style="text-align: left">es-PE</td>
<td style="text-align: left">Spanish (Peru)</td>
</tr>
<tr>
<td style="text-align: left">Español (Puerto Rico)</td>
<td style="text-align: left">es-PR</td>
<td style="text-align: left">Spanish (Puerto Rico)</td>
</tr>
<tr>
<td style="text-align: left">Español (República Dominicana)</td>
<td style="text-align: left">es-DO</td>
<td style="text-align: left">Spanish (Dominican Republic)</td>
</tr>
<tr>
<td style="text-align: left">Español (Uruguay)</td>
<td style="text-align: left">es-UY</td>
<td style="text-align: left">Spanish (Uruguay)</td>
</tr>
<tr>
<td style="text-align: left">Español (Venezuela)</td>
<td style="text-align: left">es-VE</td>
<td style="text-align: left">Spanish (Venezuela)</td>
</tr>
<tr>
<td style="text-align: left">Euskara (Espainia)</td>
<td style="text-align: left">eu-ES</td>
<td style="text-align: left">Basque (Spain)</td>
</tr>
<tr>
<td style="text-align: left">Filipino (Pilipinas)</td>
<td style="text-align: left">fil-PH</td>
<td style="text-align: left">Filipino (Philippines)</td>
</tr>
<tr>
<td style="text-align: left">Français (Canada)</td>
<td style="text-align: left">fr-CA</td>
<td style="text-align: left">French (Canada)</td>
</tr>
<tr>
<td style="text-align: left">Français (France)</td>
<td style="text-align: left">fr-FR</td>
<td style="text-align: left">French (France)</td>
</tr>
<tr>
<td style="text-align: left">Galego (España)</td>
<td style="text-align: left">gl-ES</td>
<td style="text-align: left">Galician (Spain)</td>
</tr>
<tr>
<td style="text-align: left">ქართული (საქართველო)</td>
<td style="text-align: left">ka-GE</td>
<td style="text-align: left">Georgian (Georgia)</td>
</tr>
<tr>
<td style="text-align: left">ગુજરાતી (ભારત)</td>
<td style="text-align: left">gu-IN</td>
<td style="text-align: left">Gujarati (India)</td>
</tr>
<tr>
<td style="text-align: left">Hrvatski (Hrvatska)</td>
<td style="text-align: left">hr-HR</td>
<td style="text-align: left">Croatian (Croatia)</td>
</tr>
<tr>
<td style="text-align: left">IsiZulu (Ningizimu Afrika)</td>
<td style="text-align: left">zu-ZA</td>
<td style="text-align: left">Zulu (South Africa)</td>
</tr>
<tr>
<td style="text-align: left">Íslenska (Ísland)</td>
<td style="text-align: left">is-IS</td>
<td style="text-align: left">Icelandic (Iceland)</td>
</tr>
<tr>
<td style="text-align: left">Italiano (Italia)</td>
<td style="text-align: left">it-IT</td>
<td style="text-align: left">Italian (Italy)</td>
</tr>
<tr>
<td style="text-align: left">Jawa (Indonesia)</td>
<td style="text-align: left">jv-ID</td>
<td style="text-align: left">Javanese (Indonesia)</td>
</tr>
<tr>
<td style="text-align: left">ಕನ್ನಡ (ಭಾರತ)</td>
<td style="text-align: left">kn-IN</td>
<td style="text-align: left">Kannada (India)</td>
</tr>
<tr>
<td style="text-align: left">ភាសាខ្មែរ (កម្ពុជា)</td>
<td style="text-align: left">km-KH</td>
<td style="text-align: left">Khmer (Cambodia)</td>
</tr>
<tr>
<td style="text-align: left">ລາວ (ລາວ)</td>
<td style="text-align: left">lo-LA</td>
<td style="text-align: left">Lao (Laos)</td>
</tr>
<tr>
<td style="text-align: left">Latviešu (latviešu)</td>
<td style="text-align: left">lv-LV</td>
<td style="text-align: left">Latvian (Latvia)</td>
</tr>
<tr>
<td style="text-align: left">Lietuvių (Lietuva)</td>
<td style="text-align: left">lt-LT</td>
<td style="text-align: left">Lithuanian (Lithuania)</td>
</tr>
<tr>
<td style="text-align: left">Magyar (Magyarország)</td>
<td style="text-align: left">hu-HU</td>
<td style="text-align: left">Hungarian (Hungary)</td>
</tr>
<tr>
<td style="text-align: left">മലയാളം (ഇന്ത്യ)</td>
<td style="text-align: left">ml-IN</td>
<td style="text-align: left">Malayalam (India)</td>
</tr>
<tr>
<td style="text-align: left">मराठी (भारत)</td>
<td style="text-align: left">mr-IN</td>
<td style="text-align: left">Marathi (India)</td>
</tr>
<tr>
<td style="text-align: left">Nederlands (Nederland)</td>
<td style="text-align: left">nl-NL</td>
<td style="text-align: left">Dutch (Netherlands)</td>
</tr>
<tr>
<td style="text-align: left">नेपाली (नेपाल)</td>
<td style="text-align: left">ne-NP</td>
<td style="text-align: left">Nepali (Nepal)</td>
</tr>
<tr>
<td style="text-align: left">Norsk bokmål (Norge)</td>
<td style="text-align: left">nb-NO</td>
<td style="text-align: left">Norwegian Bokmål (Norway)</td>
</tr>
<tr>
<td style="text-align: left">Polski (Polska)</td>
<td style="text-align: left">pl-PL</td>
<td style="text-align: left">Polish (Poland)</td>
</tr>
<tr>
<td style="text-align: left">Português (Brasil)</td>
<td style="text-align: left">pt-BR</td>
<td style="text-align: left">Portuguese (Brazil)</td>
</tr>
<tr>
<td style="text-align: left">Português (Portugal)</td>
<td style="text-align: left">pt-PT</td>
<td style="text-align: left">Portuguese (Portugal)</td>
</tr>
<tr>
<td style="text-align: left">Română (România)</td>
<td style="text-align: left">ro-RO</td>
<td style="text-align: left">Romanian (Romania)</td>
</tr>
<tr>
<td style="text-align: left">සිංහල (ශ්රී ලංකාව)</td>
<td style="text-align: left">si-LK</td>
<td style="text-align: left">Sinhala (Sri Lanka)</td>
</tr>
<tr>
<td style="text-align: left">Slovenčina (Slovensko)</td>
<td style="text-align: left">sk-SK</td>
<td style="text-align: left">Slovak (Slovakia)</td>
</tr>
<tr>
<td style="text-align: left">Slovenščina (Slovenija)</td>
<td style="text-align: left">sl-SI</td>
<td style="text-align: left">Slovenian (Slovenia)</td>
</tr>
<tr>
<td style="text-align: left">Urang (Indonesia)</td>
<td style="text-align: left">su-ID</td>
<td style="text-align: left">Sundanese (Indonesia)</td>
</tr>
<tr>
<td style="text-align: left">Swahili (Tanzania)</td>
<td style="text-align: left">sw-TZ</td>
<td style="text-align: left">Swahili (Tanzania)</td>
</tr>
<tr>
<td style="text-align: left">Swahili (Kenya)</td>
<td style="text-align: left">sw-KE</td>
<td style="text-align: left">Swahili (Kenya)</td>
</tr>
<tr>
<td style="text-align: left">Suomi (Suomi)</td>
<td style="text-align: left">fi-FI</td>
<td style="text-align: left">Finnish (Finland)</td>
</tr>
<tr>
<td style="text-align: left">Svenska (Sverige)</td>
<td style="text-align: left">sv-SE</td>
<td style="text-align: left">Swedish (Sweden)</td>
</tr>
<tr>
<td style="text-align: left">தமிழ் (இந்தியா)</td>
<td style="text-align: left">ta-IN</td>
<td style="text-align: left">Tamil (India)</td>
</tr>
<tr>
<td style="text-align: left">தமிழ் (சிங்கப்பூர்)</td>
<td style="text-align: left">ta-SG</td>
<td style="text-align: left">Tamil (Singapore)</td>
</tr>
<tr>
<td style="text-align: left">தமிழ் (இலங்கை)</td>
<td style="text-align: left">ta-LK</td>
<td style="text-align: left">Tamil (Sri Lanka)</td>
</tr>
<tr>
<td style="text-align: left">தமிழ் (மலேசியா)</td>
<td style="text-align: left">ta-MY</td>
<td style="text-align: left">Tamil (Malaysia)</td>
</tr>
<tr>
<td style="text-align: left">తెలుగు (భారతదేశం)</td>
<td style="text-align: left">te-IN</td>
<td style="text-align: left">Telugu (India)</td>
</tr>
<tr>
<td style="text-align: left">Tiếng Việt (Việt Nam)</td>
<td style="text-align: left">vi-VN</td>
<td style="text-align: left">Vietnamese (Vietnam)</td>
</tr>
<tr>
<td style="text-align: left">Türkçe (Türkiye)</td>
<td style="text-align: left">tr-TR</td>
<td style="text-align: left">Turkish (Turkey)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">اردو (پاکستان)</bdo></td>
<td style="text-align: left">ur-PK</td>
<td style="text-align: left">Urdu (Pakistan)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">اردو (بھارت)</bdo></td>
<td style="text-align: left">ur-IN</td>
<td style="text-align: left">Urdu (India)</td>
</tr>
<tr>
<td style="text-align: left">Ελληνικά (Ελλάδα)</td>
<td style="text-align: left">el-GR</td>
<td style="text-align: left">Greek (Greece)</td>
</tr>
<tr>
<td style="text-align: left">Български (България)</td>
<td style="text-align: left">bg-BG</td>
<td style="text-align: left">Bulgarian (Bulgaria)</td>
</tr>
<tr>
<td style="text-align: left">Русский (Россия)</td>
<td style="text-align: left">ru-RU</td>
<td style="text-align: left">Russian (Russia)</td>
</tr>
<tr>
<td style="text-align: left">Српски (Србија)</td>
<td style="text-align: left">sr-RS</td>
<td style="text-align: left">Serbian (Serbia)</td>
</tr>
<tr>
<td style="text-align: left">Українська (Україна)</td>
<td style="text-align: left">uk-UA</td>
<td style="text-align: left">Ukrainian (Ukraine)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">עברית (ישראל)</bdo></td>
<td style="text-align: left">he-IL</td>
<td style="text-align: left">Hebrew (Israel)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (إسرائيل)</bdo></td>
<td style="text-align: left">ar-IL</td>
<td style="text-align: left">Arabic (Israel)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (الأردن)</bdo></td>
<td style="text-align: left">ar-JO</td>
<td style="text-align: left">Arabic (Jordan)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (الإمارات)</bdo></td>
<td style="text-align: left">ar-AE</td>
<td style="text-align: left">Arabic (United Arab Emirates)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (البحرين)</bdo></td>
<td style="text-align: left">ar-BH</td>
<td style="text-align: left">Arabic (Bahrain)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (الجزائر)</bdo></td>
<td style="text-align: left">ar-DZ</td>
<td style="text-align: left">Arabic (Algeria)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (السعودية)</bdo></td>
<td style="text-align: left">ar-SA</td>
<td style="text-align: left">Arabic (Saudi Arabia)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (العراق)</bdo></td>
<td style="text-align: left">ar-IQ</td>
<td style="text-align: left">Arabic (Iraq)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (الكويت)</bdo></td>
<td style="text-align: left">ar-KW</td>
<td style="text-align: left">Arabic (Kuwait)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (المغرب)</bdo></td>
<td style="text-align: left">ar-MA</td>
<td style="text-align: left">Arabic (Morocco)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (تونس)</bdo></td>
<td style="text-align: left">ar-TN</td>
<td style="text-align: left">Arabic (Tunisia)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (عُمان)</bdo></td>
<td style="text-align: left">ar-OM</td>
<td style="text-align: left">Arabic (Oman)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (فلسطين)</bdo></td>
<td style="text-align: left">ar-PS</td>
<td style="text-align: left">Arabic (State of Palestine)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (قطر)</bdo></td>
<td style="text-align: left">ar-QA</td>
<td style="text-align: left">Arabic (Qatar)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (لبنان)</bdo></td>
<td style="text-align: left">ar-LB</td>
<td style="text-align: left">Arabic (Lebanon)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">العربية (مصر)</bdo></td>
<td style="text-align: left">ar-EG</td>
<td style="text-align: left">Arabic (Egypt)</td>
</tr>
<tr>
<td style="text-align: left"><bdo  dir="rtl">فارسی (ایران)</bdo></td>
<td style="text-align: left">fa-IR</td>
<td style="text-align: left">Persian (Iran)</td>
</tr>
<tr>
<td style="text-align: left">हिन्दी (भारत)</td>
<td style="text-align: left">hi-IN</td>
<td style="text-align: left">Hindi (India)</td>
</tr>
<tr>
<td style="text-align: left">ไทย (ประเทศไทย)</td>
<td style="text-align: left">th-TH</td>
<td style="text-align: left">Thai (Thailand)</td>
</tr>
<tr>
<td style="text-align: left">한국어 (대한민국)</td>
<td style="text-align: left">ko-KR</td>
<td style="text-align: left">Korean (South Korea)</td>
</tr>
<tr>
<td style="text-align: left">國語 (台灣)</td>
<td style="text-align: left">zh-TW</td>
<td style="text-align: left">Chinese, Mandarin (Traditional, Taiwan)</td>
</tr>
<tr>
<td style="text-align: left">廣東話 (香港)</td>
<td style="text-align: left">yue-Hant-HK</td>
<td style="text-align: left">Chinese, Cantonese (Traditional, Hong Kong)</td>
</tr>
<tr>
<td style="text-align: left">日本語（日本）</td>
<td style="text-align: left">ja-JP</td>
<td style="text-align: left">Japanese (Japan)</td>
</tr>
<tr>
<td style="text-align: left">普通話 (香港)</td>
<td style="text-align: left">zh-HK</td>
<td style="text-align: left">Chinese, Mandarin (Simplified, Hong Kong)</td>
</tr>
<tr>
<td style="text-align: left">普通话 (中国大陆)</td>
<td style="text-align: left">zh</td>
<td style="text-align: left">Chinese, Mandarin (Simplified, China)</td>
</tr>
</tbody>
</table>
```
