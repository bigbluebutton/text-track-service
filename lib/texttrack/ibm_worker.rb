require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"
require "sqlite3"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class IbmWorker_createJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, :symbolize_names => true)
        
      u = Caption.find(id)
      u.update(status: "finished audio conversion")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?

      job_id = SpeechToText::IbmWatsonS2T.create_job(
        audio_file_path: "#{params[:temp_storage]}/#{params[:record_id]}",
        apikey: params[:provider][:auth_file_path],
        audio: params[:record_id],
        content_type: audio_type,
        language_code: params[:caption_locale])

      u.update(status: "created job with #{u.service}")

      WM::IbmWorker_getJob.perform_async(params.to_json, u.id, job_id);
    end
  end

  class IbmWorker_getJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, job_id)
      params = JSON.parse(params_json, :symbolize_names => true)    
    
      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")

      status = "processing"
      while(status != "completed")
        callback = SpeechToText::IbmWatsonS2T.check_job(job_id, params[:provider][:auth_file_path])
        status = callback["status"]
        #sleep(300)
      end

      myarray = SpeechToText::IbmWatsonS2T.create_array_watson(callback["results"][0])

      u.update(status: "writing subtitle file from #{u.service}")
        
      SpeechToText::Util.write_to_webvtt(
          "#{params[:temp_storage]}/#{params[:record_id]}",
          "caption_#{params[:caption_locale]}.vtt",
          myarray)

      u.update(status: "done with #{u.service}")
        
      FileUtils.mv("#{params[:temp_storage]}/#{params[:record_id]}/*", "#{params[:captions_inbox_dir]}/#{params[:record_id]}", :verbose => true, :force => true)

    end
  end
end
