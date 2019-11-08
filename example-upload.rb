require "rest-client"

meeting_id = '6e35e3b2778883f5db637d7a5dba0a427f692e91-1569435655142'
site = 'http://ritz-tts3.freddixon.ca'
secret = 'HihnjRgWRhEjWWFG4YyKStyJKmN2dnDRdmPsqdAfo'
kind = 'subtitles'
lang = 'en_US'
label = 'English'
request = "putRecordingTextTrackrecordID=#{meeting_id}&kind=#{kind}&lang=#{lang}&label=#{label}"
request += secret
checksum = Digest::SHA1.hexdigest(request)

#response = RestClient.get "http://localhost:4000/caption/#{meeting_id}/en-US", {:params => {:site => "https://#{site}", :checksum => "#{checksum}"}}

request = RestClient::Request.new(
    method: :post,
    url: "http://localhost:3000/tts/uploadvtt/#{meeting_id}",
    payload: { :file => File.open('/Users/rahulrodrigues/Desktop/harddrive/D/innovation/text-track-service/6e35e3b2778883f5db637d7a5dba0a427f692e91-1569435655142/6e35e3b2778883f5db637d7a5dba0a427f692e91-1569435655142_1570639035198.vtt', 'rb'),
    :bbb_url => "#{site}", :bbb_checksum => "#{checksum}", :kind => "#{kind}", :label => "#{label}", :caption_locale => 'en-US'}
)
response = request.execute