# frozen_string_literal: true

# rubocop:disable Style/Documentation
class CaptionsController < ApplicationController
  def index
    puts 'Hello World!'
    # puts $redis.llen("foo")
  end

  # rubocop:disable Metrics/MethodLength
  def caption_recording # rubocop:disable Metrics/AbcSize
    record_id = params[:record_id]
    caption_locale = params[:caption_locale]
    provider = params[:provider]
    bbb_url = params['site']
    bbb_checksum = params['checksum']

    #bbb_url = 'ritz-tts3.freddixon.ca'
    #kind = 'subtitles'
    #label = 'English'
    #record_id = '6e35e3b2778883f5db637d7a5dba0a427f692e91-1569435655142'
    #secret = ''
    #request = "putRecordingTextTrackrecordID=#{record_id}&kind=#{kind}&lang=#{caption_locale}&label=#{label}"
    #request += secret
    #bbb_checksum = Digest::SHA1.hexdigest(request)

    puts "inside controller site -----------#{bbb_url}"
    puts "inside controller checksum = #{bbb_checksum}..................."
    # Need to find how to get the key from settings.yaml
    # props = YAML::load(File.open('settings.yaml'))
    # provider = props["default_provider"]

    # if(params[:provider].present?)
    # provider = params[:provider]
    # end
    # puts "REDIS HOST=#{redis_host} PORT=#{redis_port} PASS=#{redis_password}"

    # redis_namespace = props["redis_list_namespace"]
    #

    caption_job = { record_id: record_id,
                    caption_locale: caption_locale,
                    provider: provider,
                    bbb_url: bbb_url,
                    bbb_checksum: bbb_checksum }
    # rubocop:disable Style/GlobalVars
    $redis.lpush('caption_recordings_job', caption_job.to_json)
    # rubocop:enable Style/GlobalVars
  end
  # rubocop:enable Metrics/MethodLength

  def caption_status
    record_id = params[:record_id]
    caption_locale = params[:caption_locale]
    caption_job = { record_id: record_id,
                    caption_locale: caption_locale }
    # TODO:  pass locale as param
    caption = Caption.where(record_id: record_id)
    tp caption
  end

  private

  def find_record_by_id
    @captionfile = Captions.find(params[:id])
  end
end
# rubocop:enable Style/Documentation
