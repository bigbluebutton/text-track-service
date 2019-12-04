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
    token = params[:token]
    props = YAML.load_file('credentials.yaml')
    tts_shared_secret = props['tts_shared_secret']
    decoded_token = JWT.decode token, tts_shared_secret, true, {algorithm: 'HS256'}
    provider = decoded_token[0]['provider']
    bbb_checksum = decoded_token[0]['bbb_checksum']
    bbb_url = decoded_token[0]['bbb_url']
    kind = decoded_token[0]['kind']
    label = decoded_token[0]['label']
    start_time = decoded_token[0]['start_time']
    end_time = decoded_token[0]['end_time']

    if provider.nil?
      provider = "deepspeech"
    end                    
    
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

    caption_job = { record_id: record_id,
                    caption_locale: caption_locale,
                    provider: provider,
                    bbb_url: bbb_url,
                    bbb_checksum: bbb_checksum,
                    kind: kind,
                    label: label,
                    start_time: start_time,
                    end_time: end_time}
    

    ActiveRecord::Base.connection_pool.with_connection do
      if Caption.exists?(record_id: record_id)
        u = Caption.find_by(record_id: record_id)
        u.update(status: 'in queue',
                 service: provider,
                 caption_locale: caption_locale,
                 bbb_url: bbb_url,
                 bbb_checksum: bbb_checksum,
                 kind: kind,
                 label: label,
                 start_time: start_time.to_s,
                 end_time: end_time.to_s)
      else
        Caption.create(record_id: record_id,
                       status: 'in queue',
                       service: provider,
                       caption_locale: caption_locale,
                       bbb_url: bbb_url,
                       bbb_checksum: bbb_checksum,
                       kind: kind,
                       label: label,
                       start_time: start_time.to_s,
                       end_time: end_time.to_s)
      end        
    end            
    # rubocop:disable Style/GlobalVars
    $redis.lpush('caption_recordings_job', caption_job.to_json)
    # rubocop:enable Style/GlobalVars
  end
  # rubocop:enable Metrics/MethodLength

  private
  def find_record_by_id
    @captionfile = Captions.find(params[:id])
  end
end
# rubocop:enable Style/Documentation
