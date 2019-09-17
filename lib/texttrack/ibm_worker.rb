# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'
require 'sqlite3'
require_relative '../text-track-playback/text_track_playback_worker'
rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  # rubocop:disable Style/Documentation
  class IbmCreateJob # rubocop:disable Naming/ClassAndModuleCamelCase
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: 'finished audio conversion')
      end
      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      job_id = SpeechToText::IbmWatsonS2T.create_job(
        audio_file_path: "#{params[:temp_storage]}/#{params[:record_id]}",
        apikey: params[:provider][:auth_file_path],
        audio: params[:record_id],
        content_type: audio_type,
        language_code: params[:caption_locale]
      )
      
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "created job with #{u.service}")
      end
        
      #ActiveRecord::Base.connection_pool.with_connection do
          #u = Caption.find(id)
          #u.update(status: "waiting on job from #{u.service}")
      #end
        
      TTS::IbmGetJob.perform_async(params.to_json,
                                          u.id,
                                          job_id)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation

  # rubocop:disable Style/Documentation
  class IbmGetJob # rubocop:disable Naming/ClassAndModuleCamelCase
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    def perform(params_json, id, job_id) # rubocop:disable Metrics/AbcSize
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      ActiveRecord::Base.connection_pool.with_connection do
          u = Caption.find(id)
          u.update(status: "waiting on job from #{u.service}")
      end
        
      callback =
          SpeechToText::IbmWatsonS2T.check_job(job_id, params[:provider][:auth_file_path])
      status = callback['status']
      status_msg = "status is #{status}"
      if status == 'failed'
          puts '-------------------'
          puts status_msg
          puts '-------------------'
          ActiveRecord::Base.connection_pool.with_connection do
            u.update(status: "failed")
          end
          return
      elsif status != 'completed'
          puts '-------------------'
          puts status_msg
          puts '-------------------'
          IbmGetJob.perform_in(30, params.to_json, id, job_id)
          return
      end
        
      
      #u = nil
      myarray =
        SpeechToText::IbmWatsonS2T.create_array_watson(callback['results'][0])
      
      ActiveRecord::Base.connection_pool.with_connection do
        #u = Caption.find(id)
        u.update(status: "writing subtitle file from #{u.service}")
      end

      current_time = (Time.now.to_f * 1000).to_i

      SpeechToText::Util.write_to_webvtt(
        "#{params[:temp_storage]}/#{params[:record_id]}",
        "#{params[:record_id]}-#{current_time}-track.vtt",
        myarray
      )

      SpeechToText::Util.recording_json(
        file_path: "#{params[:temp_storage]}/#{params[:record_id]}",
        record_id: params[:record_id],
        timestamp: current_time,
        language: params[:caption_locale]
      )
      
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "inbox updated with #{u.service}")
      end

      temp_dir = "#{params[:temp_storage]}/#{params[:record_id]}"
      temp_track_vtt = "#{params[:record_id]}-#{current_time}-track.vtt"
      temp_track_json = "#{params[:record_id]}-#{current_time}-track.json"

      FileUtils.mv("#{temp_dir}/#{temp_track_vtt}",
                   "#{params[:captions_inbox_dir]}/inbox",
                   verbose: true)
      # , :force => true)

      FileUtils.mv("#{temp_dir}/#{temp_track_json}",
                   "#{params[:captions_inbox_dir]}/inbox",
                   verbose: true)
      # , :force => true)

      #FileUtils.remove_dir(temp_dir.to_s)
      
      TTP::PlaybackPutJob.perform_async(params.to_json,
                                        id,
                                        temp_track_vtt,
                                        temp_track_json)
        
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation
end
