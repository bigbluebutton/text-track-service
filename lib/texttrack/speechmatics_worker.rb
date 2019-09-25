# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'
require 'sqlite3'
rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  class SpeechmaticsCreateJob # rubocop:disable Style/Documentation
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

      # rubocop:disable Naming/VariableName
      temp_dir = "#{params[:temp_storage]}/#{params[:record_id]}"
      jobID = SpeechToText::SpeechmaticsS2T.create_job(
        "#{params[:temp_storage]}/#{params[:record_id]}",
        params[:record_id],
        audio_type,
        params[:provider][:userID],
        params[:provider][:apikey],
        params[:caption_locale],
        "#{temp_dir}/jobID_#{params[:userID]}.json"
      )
      # rubocop:enable Naming/VariableName

      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "created job with #{u.service}")
      end

      TTS::SpeechmaticsGetJob.perform_async(params.to_json,
                                            u.id,
                                            jobID)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end

  class SpeechmaticsGetJob # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Naming/UncommunicativeMethodParamName
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Naming/VariableName
    def perform(params_json, id, jobID)
      # rubocop:enable Naming/VariableName
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "waiting on job from #{u.service}")
      end

      # wait_time = 30

      wait_time = SpeechToText::SpeechmaticsS2T.check_job(
        params[:provider][:userID],
        jobID,
        params[:provider][:apikey]
      )
      unless wait_time.nil?
        puts '-------------------'
        puts "wait time is #{wait_time} seconds"
        puts '-------------------'
        SpeechmaticsGetJob.perform_in(wait_time, params.to_json, id, jobID)
        return
      end

      callback = SpeechToText::SpeechmaticsS2T.get_transcription(
        params[:provider][:userID],
        jobID,
        params[:provider][:apikey]
      )

      myarray = SpeechToText::SpeechmaticsS2T.create_array_speechmatic(callback)
      current_time = (Time.now.to_f * 1000).to_i

      data = {
        'record_id' => "#{params[:record_id]}",
        'temp_dir' => "#{params[:temp_storage]}/#{params[:record_id]}",
        'temp_track_vtt' => "#{params[:record_id]}-#{current_time}-track.vtt",
        'temp_track_json' => "#{params[:record_id]}-#{current_time}-track.json",
        'inbox' => "#{params[:captions_inbox_dir]}/inbox",
        'myarray' => myarray,
        'current_time' => current_time,
        'caption_locale' => "#{params[:caption_locale]}",
        'database_id' => "#{id}"
      }

      TTS::UtilWorker.perform_async(data.to_json)

      #TTS::PlaybackWorker.perform_async(params.to_json,
      #                                  temp_track_vtt,
      #                                  temp_track_json,
      #                                  inbox)
    end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Naming/UncommunicativeMethodParamName
    end
end
