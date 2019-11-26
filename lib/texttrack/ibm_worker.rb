# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'

rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  # rubocop:disable Style/Documentation
  class IbmCreateJob
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      
      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?
        
      start_time = Time.now.getutc.to_i
        
      job_id = SpeechToText::IbmWatsonS2T.create_job(
        audio_file_path: "#{params[:storage_dir]}/#{params[:record_id]}",
        apikey: params[:provider][:auth_file_path],
        audio: params[:record_id],
        content_type: audio_type,
        language_code: params[:caption_locale]
      )

      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "created job with #{u.service}")
      end

      TTS::IbmGetJob.perform_async(params.to_json,
                                   u.id,
                                   job_id,
                                   start_time)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation

  # rubocop:disable Style/Documentation
  class IbmGetJob
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    def perform(params_json, id, job_id, start_time) # rubocop:disable Metrics/AbcSize
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil

      callback =
        SpeechToText::IbmWatsonS2T.check_job(job_id,
                                             params[:provider][:auth_file_path])
      status = callback['status']
      status_msg = "status is #{status}"
      if status == 'failed'
        puts '-------------------'
        puts status_msg
        puts '-------------------'
        ActiveRecord::Base.connection_pool.with_connection do
          u = Caption.find(id)
          u.update(status: 'failed')
        end
        return
      elsif status != 'completed'
        puts '-------------------'
        puts status_msg
        puts '-------------------'
        IbmGetJob.perform_in(30, params.to_json, id, job_id, start_time)
        return
      end

      # u = nil
      myarray =
        SpeechToText::IbmWatsonS2T.create_array_watson(callback['results'][0])
        
      end_time = Time.now.getutc.to_i
      processing_time = end_time - start_time
      processing_time =  SpeechToText::Util.seconds_to_timestamp(processing_time)
        
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(processtime: "#{processing_time}")
      end
        
      puts '-------------------'
      puts "Processing time: #{processing_time} hr:min:sec.millsec"
      puts '-------------------'
        
      current_time = (Time.now.to_f * 1000).to_i

      data = {
        'record_id' => (params[:record_id]).to_s,
        'storage_dir' => "#{params[:storage_dir]}/#{params[:record_id]}",
        'temp_track_vtt' => "#{params[:record_id]}-#{current_time}-track.vtt",
        'temp_track_json' => "#{params[:record_id]}-#{current_time}-track.json",
        'myarray' => myarray,
        'current_time' => current_time,
        'caption_locale' => (params[:caption_locale]).to_s,
        'database_id' => id.to_s,
        'bbb_url' => params[:bbb_url],
        'bbb_checksum' => params[:bbb_checksum],
        'kind' => params[:kind],
        'label' => params[:label],
        'start_time' => params[:start_time],
        'end_time' => params[:end_time]
      }

      TTS::UtilWorker.perform_async(data.to_json)
      # TTS::PlaybackWorker.perform_async(params.to_json,
      #                                  temp_track_vtt,
      #                                  temp_track_json,
      #                                  inbox)
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation
end
