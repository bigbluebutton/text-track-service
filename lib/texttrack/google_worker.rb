# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'google/cloud/speech'
require 'google/cloud/storage'
require 'speech_to_text'
require 'sqlite3'
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  # rubocop:disable Naming/ClassAndModuleCamelCase
  class GoogleWorker_createJob # rubocop:disable Style/Documentation
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

      SpeechToText::GoogleS2T.set_environment(params[:provider][:auth_file_path])
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

      u.update(status: "created job with #{u.service}")

      WM::GoogleWorker_getJob.perform_async(params.to_json, u.id, operation_name, audio_type)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Naming/ClassAndModuleCamelCase

  # rubocop:disable Style/Documentation
  class GoogleWorker_getJob # rubocop:disable Naming/ClassAndModuleCamelCase
    include Faktory::Job
    faktory_options retry: 0

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, operation_name, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)

      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")

      callback = SpeechToText::GoogleS2T.check_job(operation_name)
      myarray = SpeechToText::GoogleS2T.create_array_google(callback['results'])

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

      SpeechToText::GoogleS2T.delete_google_storage(
        params[:provider][:google_bucket_name],
        params[:record_id],
        audio_type
      )

      u.update(status: "done with #{u.service}")

      FileUtils.mv("#{params[:temp_storage]}/#{params[:record_id]}/#{params[:record_id]}-#{current_time}-track.vtt", "#{params[:captions_inbox_dir]}/inbox", verbose: true) # , :force => true)

      FileUtils.mv("#{params[:temp_storage]}/#{params[:record_id]}/#{params[:record_id]}-#{current_time}-track.json", "#{params[:captions_inbox_dir]}/inbox", verbose: true) # , :force => true)

      FileUtils.remove_dir("#{params[:temp_storage]}/#{params[:record_id]}")

      # File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation
end
