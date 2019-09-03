require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"
require "sqlite3"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class ThreeplaymediaWorker_createJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, :symbolize_names => true)
        
      u = Caption.find(id)
      u.update(status: "finished audio conversion")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?
      job_name = rand(36**8).to_s(36)
      job_id = SpeechToText::ThreePlaymediaS2T.create_job(
        params[:provider][:auth_file_path],
        "#{params[:temp_storage]}/#{params[:record_id]}/#{params[:record_id]}.#{audio_type}",
        job_name,
        "#{params[:temp_storage]}/#{params[:record_id]}/job_file.json")

      u.update(status: "created job with #{u.service}")

      WM::ThreeplaymediaWorker_getJob.perform_async(params.to_json, u.id, job_id);
    end
  end

  class ThreeplaymediaWorker_getJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, job_id)
      params = JSON.parse(params_json, :symbolize_names => true)    
    
      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")
        
      transcript_id = SpeechToText::ThreePlaymediaS2T.order_transcript(
          params[:provider][:auth_file_path],
          job_id,
          6)
        
      status = SpeechToText::ThreePlaymediaS2T.check_status(
          params[:provider][:auth_file_path],
          transcript_id)

      status = "processing"
      while(status != "complete")
          puts status
          status = SpeechToText::ThreePlaymediaS2T.check_status(
          params[:provider][:auth_file_path],
          transcript_id)
        
          if(status == "cancelled")
            break
          end
          sleep(30)
      end
        
      if(status == "complete")
        SpeechToText::ThreePlaymediaS2T.get_vttfile(
            params[:provider][:auth_file_path],
            139,
            transcript_id,
            "#{params[:temp_storage]}/#{params[:record_id]}",
            "caption_#{params[:caption_locale]}.vtt")
          
        u.update(status: "writing subtitle file from #{u.service}")
          
            File.delete("#{params[:temp_storage]}/#{params[:record_id]}/job_file.json")
          
        u.update(status: "done with #{u.service}")
      end

      

    end
  end
end
