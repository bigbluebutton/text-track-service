require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
require "speech_to_text"
require "sqlite3"
require 'active_record'
#ENV['RAILS_ENV'] = "development"
#require_relative "../../../config/environment"
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
    
    #ActiveRecord::Base.establish_connection(
      #:adapter => "sqlite3",
      #:database => "db/development.sqlite3"
    #)
    
    #class to access database
    #class Caption < ActiveRecord::Base
    #end
    
    class AudioWorker
      include Faktory::Job
      faktory_options retry: 0
        
      def perform(data)

          #db = SQLite3::Database.open "../../../db/development.sqlite3"
          #db.execute('SELECT * FROM captions')
          

          if Caption.exists?(record_id: "#{data["recordID"]}")
              u = Caption.find_by(record_id: "#{data["recordID"]}")
              u.update(status: "Started audio conversion", service: "#{data["service"]}",caption_locale: "#{data["language_code"]}")
          else
              Caption.create(record_id: "#{data["recordID"]}", status: "Started audio conversion", service: "#{data["service"]}", caption_locale: "#{data["language_code"]}")
          end
 
          #Progress.find_by(recordID: "#{data["recordID"]}").first_or_create(recordID: "#{data["recordID"]}").update(progress: 'Started audio conversion')
          
          u = Caption.find_by(record_id: "#{data["recordID"]}")
          #Progress.create(recordID: "#{data["recordID"]}", progress: "audio conversion started")
          
         
          if(u.service == "ibm")
              SpeechToText::Util.video_to_audio(video_file_path: "#{data["published_file_path"]}/#{data["recordID"]}/video",video_name:"video",video_content_type: "mp4",audio_file_path: "#{data["published_file_path"]}/#{data["recordID"]}",audio_name: "#{data["recordID"]}",audio_content_type: "wav") 
          elsif(u.service == "google")
              SpeechToText::Util.video_to_audio(video_file_path: "#{data["published_file_path"]}/#{data["recordID"]}/video",video_name:"video",video_content_type: "mp4",audio_file_path: "#{data["published_file_path"]}/#{data["recordID"]}",audio_name: "#{data["recordID"]}",audio_content_type: "wav")
          elsif(u.service == "speechmatics")
              SpeechToText::Util.video_to_audio(video_file_path: "#{data["published_file_path"]}/#{data["recordID"]}/video",video_name:"video",video_content_type: "mp4",audio_file_path: "#{data["published_file_path"]}/#{data["recordID"]}",audio_name: "#{data["recordID"]}",audio_content_type: "mp3")
          else
              SpeechToText::Util.video_to_audio(data["published_file_path"],data["recordID"],data["service"]);
          end

          if(data["service"] === "google")
            WM::GoogleWorker_1.perform_async(data, u.id);
          elsif(data["service"] === "ibm") 
            WM::IbmWorker_1.perform_async(data, u.id);
          elsif(data["service"] === "deepspeech") 
            WM::DeepspeechWorker.perform_async(data, u.id);
          elsif(data["service"] === "speechmatics") 
            WM::SpeechmaticsWorker_1.perform_async(data, u.id);
          end


      end
    end
    
    class GoogleWorker_1
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          #if(data["service"] === "google")
 
              u = Caption.find(id)
              u.update(status: "finished audio conversion")
              
              
              SpeechToText::GoogleS2T.set_environment(data["auth_key"])
              SpeechToText::GoogleS2T.google_storage("#{data["published_file_path"]}/#{data["recordID"]}","#{data["recordID"]}","wav",data["google_bucket_name"])
              operation_name = SpeechToText::GoogleS2T.create_job("#{data["recordID"]}","wav",data["google_bucket_name"], "#{data["language_code"]}")
              
              u.update(status: "created job with #{u.service}")      
          
              WM::GoogleWorker_2.perform_async(data, u.id, operation_name);
              
              

          #end
      end
    end
    
    class GoogleWorker_2
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id, operation_name)
          #if(data["service"] === "google")
          
             #google_speech_to_text 
              u = Caption.find(id)
              u.update(status: "waiting on job from #{u.service}")
              
              #SpeechToText::GoogleS2T.google_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"],data["google_bucket_name"])
          
              callback = SpeechToText::GoogleS2T.check_job(operation_name)
          
              myarray = SpeechToText::GoogleS2T.create_array_google(callback["results"])
          
              u.update(status: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt("#{data["published_file_path"]}/#{data["recordID"]}","vttfile_#{data["language_code"]}.vtt",myarray)
              
              SpeechToText::GoogleS2T.delete_google_storage(data["google_bucket_name"], "#{data["recordID"]}", "wav")
              
              u.update(status: "done with #{u.service}")
          
              #File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")
              
          #end
      end
    end
    
    class IbmWorker_1
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Caption.find(id)
              u.update(status: "finished audio conversion")
             #SpeechToText::IbmWatsonS2T.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
              
              job_id = SpeechToText::IbmWatsonS2T.create_job(audio_file_path:"#{data["published_file_path"]}/#{data["recordID"]}",apikey:"#{data["auth_key"]}",audio:"#{data["recordID"]}",content_type:"wav",language_code: data["language_code"])
          
              #job_id = SpeechToText::IbmWatsonS2T.create_job(data["published_file_path"],data["recordID"],data["auth_key"])
              
              u.update(status: "created job with #{u.service}")
              
              WM::IbmWorker_2.perform_async(data, u.id, job_id);
      end
    end
    
    class IbmWorker_2
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id, job_id)
              
              u = Caption.find(id)
              u.update(status: "waiting on job from #{u.service}")
          
             #SpeechToText::IbmWatsonS2T.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
              status = "processing"
              while(status != "completed")
                callback = SpeechToText::IbmWatsonS2T.check_job(job_id, data["auth_key"])
                
                status = callback["status"]
                #sleep(300)
              end
          
              myarray = SpeechToText::IbmWatsonS2T.create_array_watson(callback["results"][0])
          
              u.update(status: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt("#{data["published_file_path"]}/#{data["recordID"]}","vttfile_#{data["language_code"]}.vtt",myarray)
          
              u.update(status: "done with #{u.service}")
          
              
          
      end
    end
    
    class DeepspeechWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Caption.find(id)
              u.update(status: "finished audio & started #{u.service} transcription process")
             SpeechToText::MozillaDeepspeechS2T.mozilla_speech_to_text(data["published_file_path"],data["recordID"],data["deepspeech_model_path"])
              
              u.update(status: "done with #{u.service}")
          
      end
    end
    
    class SpeechmaticsWorker_1
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Caption.find(id)
              u.update(status: "finished audio & started #{u.service} transcription process")
             #SpeechToText::SpeechmaticsS2T.speechmatics_speech_to_text(data["published_file_path"],data["recordID"],data["userID"],data["auth_key"])
             jobID = SpeechToText::SpeechmaticsS2T.create_job("#{data["published_file_path"]}/#{data["recordID"]}",data["recordID"],"mp3",data["userID"],data["auth_key"],"#{data["published_file_path"]}/#{data["recordID"]}/jobID_#{data["userID"]}.json")
              
              u.update(status: "created job with #{u.service}")
          
              WM::SpeechmaticsWorker_2.perform_async(data, u.id, jobID);
          
      end
    end
    
    class SpeechmaticsWorker_2
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id, jobID)
          
              
              u = Caption.find(id)
              u.update(status: "waiting on job from #{u.service}")
             
              wait_time = 30
              while !wait_time.nil?
                wait_time = SpeechToText::SpeechmaticsS2T.check_job(data["userID"],jobID,data["auth_key"],"#{data["published_file_path"]}/#{data["recordID"]}/jobdetails_#{data["userID"]}.json")
                  
                if !wait_time.nil?
                    sleep(wait_time)
                end
                
              end
          
              callback = SpeechToText::SpeechmaticsS2T.get_transcription(data["userID"],jobID,data["auth_key"],"#{data["published_file_path"]}/#{data["recordID"]}/transcription_#{data["userID"]}.json")
          
              
              myarray = SpeechToText::SpeechmaticsS2T.create_array_speechmatic(callback)
                
              u.update(status: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt("#{data["published_file_path"]}/#{data["recordID"]}","vttfile_#{data["language_code"]}.vtt",myarray)
              
          
              u.update(status: "done with #{u.service}")
              
              File.delete("#{data["published_file_path"]}/#{data["recordID"]}/jobID_#{data["userID"]}.json")
              File.delete("#{data["published_file_path"]}/#{data["recordID"]}/jobdetails_#{data["userID"]}.json")
              File.delete("#{data["published_file_path"]}/#{data["recordID"]}/transcription_#{data["userID"]}.json")
              
          
      end
    end
end
