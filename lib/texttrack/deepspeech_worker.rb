require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"
require "sqlite3"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class DeepspeechWorker_createJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, :symbolize_names => true)    
    
      u = Caption.find(id)
      u.update(status: "finished audio & started #{u.service} transcription process")
        
     job_id = SpeechToText::MozillaDeepspeechS2T.create_job(
          "#{params[:recordings_dir]}/#{params[:record_id]}/#{params[:record_id]}.#{audio_type}",
          "#{params[:recordings_dir]}/#{params[:record_id]}/#{params[:record_id]}_jobdetails.json"
          )
        
      u.update(status: "created job with #{u.service}")
        
      WM::DeepspeechWorker_getJob.perform_async(params.to_json, u.id, job_id);

    end
  end
    
    
  class DeepspeechWorker_getJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, job_id)
      params = JSON.parse(params_json, :symbolize_names => true)
              
      u = Caption.find(id)
      u.update(status: "waiting on job from #{u.service}")
      
      status = "inProgress"
      while(status != "completed")
        status = SpeechToText::MozillaDeepspeechS2T.checkstatus(job_id)
      end
        
      callback_json = SpeechToText::MozillaDeepspeechS2T.order_transcript(job_id)
        
      u.update(status: "writing subtitle file from #{u.service}")
        
      myarray = SpeechToText::MozillaDeepspeechS2T.create_mozilla_array(callback_json)
        
        
      SpeechToText::Util.write_to_webvtt(
        "#{params[:recordings_dir]}/#{params[:record_id]}",
        "caption_#{params[:caption_locale]}.vtt",
        myarray
      )

      u.update(status: "done with #{u.service}")
        
      File.delete("#{params[:recordings_dir]}/#{params[:record_id]}/#{params[:record_id]}_jobdetails.json")

    end
  end
end
