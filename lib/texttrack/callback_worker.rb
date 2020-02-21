# frozen_string_literal: true

require 'connection_pool'
require 'faktory'
require 'httparty'
require 'json'
require 'fileutils'

module TTS
  class CallbackWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1
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
      id = data['id']
      caption_locale = caption_locale.sub('-', '_')
        

      # prepare post data
      uri = URI("#{bbb_url}/bigbluebutton/api/putRecordingTextTrack?recordID=#{record_id}&kind=#{kind}&lang=#{caption_locale}&label=#{label}&checksum=#{bbb_checksum}")
      request = Net::HTTP::Post.new(uri)
      form_data = [['file', File.open("#{storage_dir}/#{record_id}-#{current_time}-track.vtt")]] # or File.open() in case of local file
      request.set_form form_data, 'multipart/form-data'
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http| # pay attention to use_ssl if you need it
        http.request(request)
      end

      ActiveRecord::Base.connection_pool.with_connection do
        if id.nil?
          u = Caption.find_by(record_id: record_id)
        else 
          u = Caption.find(id)
        end
        u.update(status: "uploaded to #{u.bbb_url}")
      end
      # print response
        
      puts response.body.to_s
      puts "storage => #{storage_dir}"
      if Dir.exist?(storage_dir)
        FileUtils.rm_rf(storage_dir)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
