require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
require "speech_to_text"
require "sqlite3"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class GoogleWorker_1
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id)
      params = JSON.parse(param_json, :symbolize_names => true)
        
      u = Caption.find(id)
      u.update(status: "finished audio conversion")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      SpeechToText::GoogleS2T.set_environment(params[:auth_key])
      SpeechToText::GoogleS2T.google_storage(
        params[:recordings_dir],
        params[:record_id],
        "wav",
        params[:google_bucket_name]
      )
      operation_name = SpeechToText::GoogleS2T.create_job(
        params[:record_id],
        "wav",
        params[:google_bucket_name],
        params[:caption_locale]
      )

      u.update(status: "created job with #{u.service}")

      WM::GoogleWorker_2.perform_async(params.to_json, u.id, operation_name)
    end
  end

  class GoogleWorker_2
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, operation_name)
      params = JSON.parse(param_json, :symbolize_names => true)
        
      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")

      callback = SpeechToText::GoogleS2T.check_job(operation_name)
      myarray = SpeechToText::GoogleS2T.create_array_google(callback["results"])

      u.update(status: "writing subtitle file from #{u.service}")
      SpeechToText::Util.write_to_webvtt(
        params[:recordings_dir],
        "vttfile_#{params[:caption_locale]}.vtt",
        myarray
      )

      SpeechToText::GoogleS2T.delete_google_storage(
        params[:google_bucket_name],
        params[:record_id],
        "wav"
      )

      u.update(status: "done with #{u.service}")

      #File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")
    end
  end
end
