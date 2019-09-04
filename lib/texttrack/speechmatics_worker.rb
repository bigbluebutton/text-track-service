require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"
require "sqlite3"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class SpeechmaticsWorker_createJob
    include Faktory::Job
    faktory_options retry: 0

    def perform(params_json, id, audio_type)
      params = JSON.parse(params_json, :symbolize_names => true)    
    
      u = Caption.find(id)
      u.update(status: "finished audio & started #{u.service} transcription process")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?
        
      jobID = SpeechToText::SpeechmaticsS2T.create_job(
          "#{params[:temp_storage]}/#{params[:record_id]}",
          params[:record_id],
          audio_type,
          params[:provider][:userID],
          params[:provider][:apikey],
          params[:caption_locale],
          "#{params[:temp_storage]}/#{params[:record_id]}/jobID_#{params[:userID]}.json")

      u.update(status: "created job with #{u.service}")
        
      WM::SpeechmaticsWorker_getJob.perform_async(params.to_json, u.id, jobID);

    end
  end
    
    
  class SpeechmaticsWorker_getJob
      include Faktory::Job
      faktory_options retry: 0

      def perform(params_json, id, jobID)
              params = JSON.parse(params_json, :symbolize_names => true)
              
              u = Caption.find(id)
              u.update(status: "waiting on job from #{u.service}")
             
              wait_time = 30
              while !wait_time.nil?
                wait_time = SpeechToText::SpeechmaticsS2T.check_job(
                    params[:provider][:userID],
                    jobID,
                    params[:provider][:apikey])
                  
                if !wait_time.nil?
                    sleep(wait_time)
                end
                
              end
          
              callback = SpeechToText::SpeechmaticsS2T.get_transcription(
                  params[:provider][:userID],
                  jobID,
                  params[:provider][:apikey])
          
              
              myarray = SpeechToText::SpeechmaticsS2T.create_array_speechmatic(callback)
                
              u.update(status: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt(
                  "#{params[:temp_storage]}/#{params[:record_id]}",
                  "caption_#{params[:caption_locale]}.vtt",
                  myarray)
              
          
              u.update(status: "done with #{u.service}")
              
              File.delete("#{params[:temp_storage]}/#{params[:record_id]}/jobID_#{params[:userID]}.json")
          
              FileUtils.mv("#{params[:temp_storage]}/#{params[:record_id]}/caption_#{params[:caption_locale]}.vtt", "#{params[:captions_inbox_dir]}/inbox", :verbose => true)#, :force => true)
        
              FileUtils.mv("#{params[:temp_storage]}/#{params[:record_id]}/captions.json", "#{params[:captions_inbox_dir]}/inbox", :verbose => true)#, :force => true)
        
              FileUtils.remove_dir("#{params[:temp_storage]}/#{params[:record_id]}")
              
          
      end
    end
end
