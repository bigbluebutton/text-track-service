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

    def perform(data, id)
      u = Caption.find(id)
      u.update(progress: "finished audio conversion")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      SpeechToText::GoogleS2T.set_environment(data["auth_key"])
      SpeechToText::GoogleS2T.google_storage(
        data["published_file_path"],
        data["recordID"],
        data["google_bucket_name"]
      )
      operation_name = SpeechToText::GoogleS2T.create_job(
        data["recordID"],
        data["google_bucket_name"]
      )

      u.update(progress: "created job with #{u.service}")

      WM::GoogleWorker_2.perform_async(data, u.id, operation_name)
    end
  end

  class GoogleWorker_2
    include Faktory::Job
    faktory_options retry: 0

    def perform(data, id, operation_name)
      u = Caption.find(id)
      u.update(progress: "waiting on job from #{u.service}")

      callback = SpeechToText::GoogleS2T.check_job(operation_name)
      myarray = SpeechToText::GoogleS2T.create_array_google(callback["results"])

      u.update(progress: "writing subtitle file from #{u.service}")
      SpeechToText::Util.write_to_webvtt(
        data["published_file_path"],
        data["recordID"],
        myarray
      )

      SpeechToText::GoogleS2T.delete_google_storage(
        data["google_bucket_name"],
        data["recordID"]
      )

      u.update(progress: "done with #{u.service}")

      File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")
    end
  end
end
