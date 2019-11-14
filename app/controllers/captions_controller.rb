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
                    label: label }
    

    ActiveRecord::Base.connection_pool.with_connection do
      if Caption.exists?(record_id: record_id)
        u = Caption.find_by(record_id: record_id)
        u.update(status: 'in queue',
                 service: provider,
                 caption_locale: caption_locale)
      else
        Caption.create(record_id: record_id,
                       status: 'in queue',
                       service: provider,
                       caption_locale: caption_locale,
                       bbb_url: bbb_url,
                       bbb_checksum: bbb_checksum,
                       kind: kind,
                       label: label)
      end        
    end            
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
    @caption = Caption.where(record_id: record_id)
    tp @caption
  end
    
  def caption_all_status
    # TODO:  pass locale as param
    @caption = Caption.all
    @caption.each do |c|
        tp c
    end
    render :json => @caption
    #tp caption
  end
    
  def caption_processed_status
    # TODO:  pass locale as param
    @processed_jobs = Caption.where('status LIKE ?', 'uploaded%')

    @processed_jobs.each do |p|
        tp p
    end
  end
    
  def caption_failed_status
    # TODO:  pass locale as param
    @failed_jobs = Caption.where.not('status LIKE ?', 'uploaded%')

    @failed_jobs.each do |f|
        tp f
    end
  end

  private

  def find_record_by_id
    @captionfile = Captions.find(params[:id])
  end
end
# rubocop:enable Style/Documentation
