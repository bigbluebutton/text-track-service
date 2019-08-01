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

    def perform(params_json, id)
      params = JSON.parse(param_json, :symbolize_names => true)
        
      u = Caption.find(id)
      u.update(status: "finished audio conversion")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      job_id = SpeechToText::IbmWatsonS2T.create_job(
        audio_file_path: params[:recordings_dir],
        apikey: params[:auth_key],
        audio: params[:record_id],
        content_type:"wav",
        language_code: params[:caption_locale])

      u.update(status: "created job with #{u.service}")

      WM::IbmWorker_2.perform_async(params.to_json, u.id, job_id);
    end
  end

  class IbmWorker_2
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, job_id)
      params = JSON.parse(param_json, :symbolize_names => true)    
    
      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")

      status = "processing"
      while(status != "completed")
        callback = SpeechToText::IbmWatsonS2T.check_job(job_id, params[:auth_key])
        status = callback["status"]
      end

      myarray = SpeechToText::IbmWatsonS2T.create_array_watson(callback["results"][0])

      u.update(status: "writing subtitle file from #{u.service}")
      SpeechToText::Util.write_to_webvtt(
          params[:recordings_dir],
          "vttfile_#{params[:caption_locale]}.vtt",
          myarray)

      u.update(status: "done with #{u.service}")

    end
  end
end
