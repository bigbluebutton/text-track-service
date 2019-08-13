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
          "#{params[:recordings_dir]}/#{params[:record_id]}",
          params[:record_id],
          audio_type,
          params[:userID],
          params[:auth_key],
          params[:caption_locale],
          "#{params[:recordings_dir]}/#{params[:record_id]}/jobID_#{params[:userID]}.json")

      u.update(status: "done with #{u.service}")
        
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
                    params[:userID],
                    jobID,
                    params[:auth_key],
                    "#{params[:recordings_dir]}/#{params[:record_id]}/jobdetails_#{params[:userID]}.json")
                  
                if !wait_time.nil?
                    sleep(wait_time)
                end
                
              end
          
              callback = SpeechToText::SpeechmaticsS2T.get_transcription(
                  params[:userID],
                  jobID,
                  params[:auth_key],
                  "#{params[:recordings_dir]}/#{params[:record_id]}/transcription_#{params[:userID]}.json")
          
              
              myarray = SpeechToText::SpeechmaticsS2T.create_array_speechmatic(callback)
                
              u.update(status: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt(
                  "#{params[:recordings_dir]}/#{params[:record_id]}",
                  "vttfile_#{params[:caption_locale]}.vtt",
                  myarray)
              
          
              u.update(status: "done with #{u.service}")
              
              File.delete("#{params[:recordings_dir]}/#{params[:record_id]}/jobID_#{params[:userID]}.json")
              File.delete("#{params[:recordings_dir]}/#{params[:record_id]}/jobdetails_#{params[:userID]}.json")
              File.delete("#{params[:recordings_dir]}/#{params[:record_id]}/transcription_#{params[:userID]}.json")
              
          
      end
    end
end
