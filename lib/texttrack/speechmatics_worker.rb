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
  class SpeechmaticsCreateJob # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
        
      start_time = Time.now.getutc.to_i

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      # rubocop:disable Naming/VariableName
      storage_dir = "#{params[:storage_dir]}/#{params[:record_id]}"
      jobID = SpeechToText::SpeechmaticsS2T.create_job(
        "#{params[:storage_dir]}/#{params[:record_id]}",
        params[:record_id],
        audio_type,
        params[:provider][:userID],
        params[:provider][:apikey],
        params[:caption_locale],
        "#{storage_dir}/jobID_#{params[:userID]}.json"
      )
      # rubocop:enable Naming/VariableName

      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "created job with #{u.service}")
      end

      TTS::SpeechmaticsGetJob.perform_async(params.to_json,
                                            u.id,
                                            jobID,
                                            start_time)
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
    def perform(params_json, id, jobID, start_time)
      # rubocop:enable Naming/VariableName
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil

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
        SpeechmaticsGetJob.perform_in(wait_time, 
                                      params.to_json, 
                                      id, 
                                      jobID, 
                                      start_time)
        return
      end

      callback = SpeechToText::SpeechmaticsS2T.get_transcription(
        params[:provider][:userID],
        jobID,
        params[:provider][:apikey]
      )

      myarray = SpeechToText::SpeechmaticsS2T.create_array_speechmatic(callback)
        
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

    end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Naming/UncommunicativeMethodParamName
    end
end
