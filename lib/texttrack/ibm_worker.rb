# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'
require 'sqlite3'
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  # rubocop:disable Style/Documentation
  class IbmWorker_createJob # rubocop:disable Naming/ClassAndModuleCamelCase
    include Faktory::Job
    faktory_options retry: 0

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)

      u = Caption.find(id)
      u.update(status: 'finished audio conversion')

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

      u.update(status: "created job with #{u.service}")

      TTS::IbmWorker_getJob.perform_async(params.to_json,
                                          u.id,
                                          job_id)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation

  # rubocop:disable Style/Documentation
  class IbmWorker_getJob # rubocop:disable Naming/ClassAndModuleCamelCase
    include Faktory::Job
    faktory_options retry: 0

    # rubocop:disable Metrics/MethodLength
    def perform(params_json, id, job_id) # rubocop:disable Metrics/AbcSize
      params = JSON.parse(params_json, symbolize_names: true)

      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")

      status = 'processing'
      while status != 'completed'
        callback = SpeechToText::IbmWatsonS2T.check_job(job_id, params[:provider][:auth_file_path])
        status = callback['status']
        sleep(30) # 0)
        next unless status != 'processing' && status != 'completed'

        puts '-------------------'
        puts "status is #{status}"
        puts '-------------------'
        break
      end

      myarray = SpeechToText::IbmWatsonS2T.create_array_watson(callback['results'][0])

      u.update(status: "writing subtitle file from #{u.service}")

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

      u.update(status: "done with #{u.service}")

      temp_dir = "#{params[:temp_storage]}/#{params[:record_id]}"
      temp_track_vtt = "#{params[:record_id]}-#{current_time}-track.vtt"
      temp_track_json = "#{params[:record_id]}-#{current_time}-track.json"

      FileUtils.mv("#{track_dir}/#{temp_track_vtt}",
                   "#{params[:captions_inbox_dir]}/inbox",
                   verbose: true)
      # , :force => true)

      FileUtils.mv("#{track_dir}/#{temp_track_json}",
                   "#{params[:captions_inbox_dir]}/inbox",
                   verbose: true)
      # , :force => true)

      FileUtils.remove_dir(temp_dir.to_s)
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation
end
