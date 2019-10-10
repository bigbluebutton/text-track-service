# frozen_string_literal: true

require 'connection_pool'
require 'faktory'
require 'httparty'

module TTS
  class CallbackWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params)
      data = JSON.load params
      record_id = data['record_id']
      storage_dir = data['storage_dir']
      caption_locale = data['caption_locale']
      current_time = data['current_time']
      bbb_url = data['bbb_url']
      bbb_checksum = data['bbb_checksum']
      kind = data['kind']
      label = data['label']
      caption_locale = caption_locale.sub('-', '_')


      # prepare post data
      uri = URI("#{bbb_url}/bigbluebutton/api/putRecordingTextTrack?recordID=#{record_id}&kind=#{kind}&lang=#{caption_locale}&label=#{label}&checksum=#{bbb_checksum}")
      request = Net::HTTP::Post.new(uri)
      form_data = [['file', File.open("#{storage_dir}/#{record_id}-#{current_time}-track.vtt")]] # or File.open() in case of local file
      request.set_form form_data, 'multipart/form-data'
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http| # pay attention to use_ssl if you need it
        http.request(request)
      end

      # print response
      puts response.body.to_s
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
