require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"
require "sqlite3"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class IbmWorker_1
    include Faktory::Job
    faktory_options retry: 0

    def perform(data, id)
      u = Caption.find(id)
      u.update(progress: "finished audio conversion")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      job_id = SpeechToText::IbmWatsonS2T.create_job(data["published_file_path"],data["recordID"],data["auth_key"])

      u.update(progress: "created job with #{u.service}")

      WM::IbmWorker_2.perform_async(data, u.id, job_id);
    end
  end

  class IbmWorker_2
    include Faktory::Job
    faktory_options retry: 0

    def perform(data, id, job_id)
      u = Caption.find(id)
      u.update(progress: "waiting on job from #{u.service}")

      status = "processing"
      while(status != "completed")
        callback = SpeechToText::IbmWatsonS2T.check_job(job_id,data["auth_key"])
        status = callback["status"]
      end

      myarray = SpeechToText::IbmWatsonS2T.create_array_watson(callback["results"][0])

      u.update(progress: "writing subtitle file from #{u.service}")
      SpeechToText::Util.write_to_webvtt(data["published_file_path"],data["recordID"],myarray)

      u.update(progress: "done with #{u.service}")

      File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")

    end
  end
end
