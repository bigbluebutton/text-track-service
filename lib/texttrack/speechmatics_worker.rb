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
  # rubocop:disable Naming/ClassAndModuleCamelCase
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
  # rubocop:enable Naming/ClassAndModuleCamelCase

  # rubocop:disable Naming/ClassAndModuleCamelCase
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

      wait_time = 30
        
      wait_time = SpeechToText::SpeechmaticsS2T.check_job(
          params[:provider][:userID],
          jobID,
          params[:provider][:apikey]
        )
      if wait_time != nil
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
      
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "writing subtitle file from #{u.service}")
      end

      current_time = (Time.now.to_f * 1000).to_i

      SpeechToText::Util.write_to_webvtt(
        vtt_file_path: "#{params[:temp_storage]}/#{params[:record_id]}",
        vtt_file_name: "#{params[:record_id]}-#{current_time}-track.vtt",
        myarray: myarray
      )

      SpeechToText::Util.recording_json(
        file_path: "#{params[:temp_storage]}/#{params[:record_id]}",
        record_id: params[:record_id],
        timestamp: current_time,
        language: params[:caption_locale]
      )
        
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "done with #{u.service}")
      end

      temp_dir = "#{params[:temp_storage]}/#{params[:record_id]}"
      temp_track_vtt = "#{params[:record_id]}-#{current_time}-track.vtt"
      temp_track_json = "#{params[:record_id]}-#{current_time}-track.json"

      File.delete("#{temp_dir}/jobID_#{params[:userID]}.json")

      FileUtils.mv("#{temp_dir}/#{temp_track_vtt}",
                   "#{params[:captions_inbox_dir]}/inbox",
                   verbose: true) # , :force => true)

      FileUtils.mv("#{temp_dir}/#{temp_track_json}",
                   "#{params[:captions_inbox_dir]}/inbox",
                   verbose: true) # , :force => true)

      FileUtils.remove_dir(temp_dir.to_s)
    end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Naming/UncommunicativeMethodParamName
    end
  # rubocop:enable Naming/ClassAndModuleCamelCase
end
