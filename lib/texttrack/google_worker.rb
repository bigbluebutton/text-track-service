# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'google/cloud/speech'
require 'google/cloud/storage'
require 'speech_to_text'

rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
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
        "#{params[:storage_dir]}/#{params[:record_id]}",
        'audio',
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

  # rubocop:disable Style/Documentation
  class GoogleGetJob
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
      status = SpeechToText::GoogleS2T.check_status(operation_name)

      status_msg = "status is #{status}"
      if status == 'failed'
        puts '-------------------'
        puts status_msg
        puts '-------------------'
        ActiveRecord::Base.connection_pool.with_connection do
          u.update(status: 'failed')
        end
        return
      elsif status != 'completed'
        puts '-------------------'
        puts status_msg
        puts '-------------------'
        GoogleGetJob.perform_in(30,
                                params.to_json,
                                id,
                                operation_name,
                                audio_type)
        return
      end

      callback = SpeechToText::GoogleS2T.get_words(operation_name)
      myarray = SpeechToText::GoogleS2T.create_array_google(callback['results'])
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
        'label' => params[:label]
      }

      TTS::UtilWorker.perform_async(data.to_json)

      #  TTS::PlaybackWorker.perform_async(params.to_json,
      #                                    temp_track_vtt,
      #                                    temp_track_json,
      #                                    inbox)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation
end
