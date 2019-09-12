# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'google/cloud/speech'
require 'google/cloud/storage'
require 'speech_to_text'
require 'sqlite3'
rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  # rubocop:disable Naming/ClassAndModuleCamelCase
  class GoogleCreateJob # rubocop:disable Style/Documentation
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

      auth_file = params[:provider][:auth_file_path]

      SpeechToText::GoogleS2T.set_environment(auth_file)
      SpeechToText::GoogleS2T.google_storage(
        "#{params[:temp_storage]}/#{params[:record_id]}",
        params[:record_id],
        audio_type,
        params[:provider][:google_bucket_name]
      )
      operation_name = SpeechToText::GoogleS2T.create_job(
        params[:record_id],
        audio_type,
        params[:provider][:google_bucket_name],
        params[:caption_locale]
      )
      
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "created job with #{u.service}")
      end

      TTS::GoogleGetJob.perform_async(params.to_json,
                                             u.id,
                                             operation_name,
                                             audio_type)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Naming/ClassAndModuleCamelCase

  # rubocop:disable Style/Documentation
  class GoogleGetJob # rubocop:disable Naming/ClassAndModuleCamelCase
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, operation_name, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "waiting on job from #{u.service}")
      end
      
      # Google will not return until check_job is done, occupies thread
      callback = SpeechToText::GoogleS2T.check_job(operation_name)
      myarray = SpeechToText::GoogleS2T.create_array_google(callback['results'])
      
      ActiveRecord::Base.connection_pool.with_connection do
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

      SpeechToText::GoogleS2T.delete_google_storage(
        params[:provider][:google_bucket_name],
        params[:record_id],
        audio_type
      )
      
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "done with #{u.service}")
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

      FileUtils.remove_dir(temp_dir.to_s)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation
end
