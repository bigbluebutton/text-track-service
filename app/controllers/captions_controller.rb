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
    bbb_checksum = params[:bbb_checksum]
    bbb_url = params[:bbb_url]
    kind = params[:kind]
    label = params[:label]

    props = YAML.load_file('settings.yaml')
    storage_dir = props['storage_dir']
    storage_dir = "#{Rails.root}/storage"
    record_dir = "#{storage_dir}/#{record_id}"
    system(" /data")
    unless Dir.exist?(record_dir)
      FileUtils.mkdir_p(record_dir)
    end

    audio = params['file']
    File.open("#{record_dir}/audio_temp.wav","wb") do |file|
      file.write audio.read
    end

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
                    bbb_checksum: bbb_checksum,
                    kind: kind,
                    label: label }
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
