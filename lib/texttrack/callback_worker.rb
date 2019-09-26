# frozen_string_literal: true

require 'connection_pool'
require 'faktory'

module TTS
  class CallbackWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params)
      data = JSON.load params
      record_id = data['record_id']
      inbox = data['inbox']
      caption_locale = data['caption_locale']
      current_time = data['current_time']
      url = data['url']
      url = 'dev22.bigbluebutton.org'
      url = 'ritz-tts3.freddixon.ca'
      checksum = data['checksum']

      # current_time = (Time.now.to_f * 1000).to_i
      kind = 'subtitles'
      caption_locale = 'en_US'
      label = 'English'
      record_id = '6e35e3b2778883f5db637d7a5dba0a427f692e91-1569435655142'
      secret = 'KSWujC8QuFuDTOs5277AZ8llDv4I5bQnh1lAvv7r8'
      secret = 'HihnjRgWRhEjWWFG4YyKStyJKmN2dnDRdmPsqdAfo'
      # original_filename = "captions_en-US.vtt"
      # temp_filename = "#{recordID}-#{current_time}-track.txt"
      request = "putRecordingTextTrackrecordID=#{record_id}&kind=#{kind}&lang=#{caption_locale}&label=#{label}"
      request += secret
      checksum = Digest::SHA1.hexdigest(request)

      # prepare post data
      uri = URI("https://#{url}/bigbluebutton/api/putRecordingTextTrack?recordID=#{record_id}&kind=#{kind}&lang=#{caption_locale}&label=#{label}&checksum=#{checksum}")
      request = Net::HTTP::Post.new(uri)
      form_data = [['file', File.open("#{inbox}/6e35e3b2778883f5db637d7a5dba0a427f692e91-1569435655142.vtt")]] # or File.open() in case of local file
      # form_data = [['file',File.open("#{inbox}/#{record_id}-#{current_time}-track.vtt") ]] # or File.open() in case of local file

      request.set_form form_data, 'multipart/form-data'
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http| # pay attention to use_ssl if you need it
        http.request(request)
      end

      # print response
      puts response.body.to_s
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
