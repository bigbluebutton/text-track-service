require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
require "speech_to_text"
require "sqlite3"
ENV['RAILS_ENV'] = "development"
require_relative "../../../config/environment"

module WM
    
    class AudioWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data)
          
          if Caption.exists?(recordID: "#{data["recordID"]}")
              u = Caption.find_by(recordID: "#{data["recordID"]}")
              u.update(progress: "Started audio conversion", service: "#{data["service"]}")
          else
              Caption.create(recordID: "#{data["recordID"]}", progress: "Started audio conversion", service: "#{data["service"]}")
          end
          
          #Progress.find_by(recordID: "#{data["recordID"]}").first_or_create(recordID: "#{data["recordID"]}").update(progress: 'Started audio conversion')
          
          u = Caption.find_by(recordID: "#{data["recordID"]}")
          #Progress.create(recordID: "#{data["recordID"]}", progress: "audio conversion started")
          
          SpeechToText::Util.video_to_audio(data["published_file_path"],data["recordID"],data["service"]);

          if(data["service"] === "google")
            #ENV['GOOGLE_APPLICATION_CREDENTIALS'] = "#{data["auth_key"]}";
            WM::GoogleWorker_1.perform_async(data, u.id);
          elsif(data["service"] === "ibm") 
            WM::IbmWorker_1.perform_async(data, u.id);
          elsif(data["service"] === "deepspeech") 
            WM::DeepspeechWorker.perform_async(data, u.id);
          elsif(data["service"] === "speechmatics") 
            WM::SpeechmaticsWorker.perform_async(data, u.id);
          end


      end
    end
    
    class GoogleWorker_1
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          #if(data["service"] === "google")

             #google_speech_to_text 
              u = Caption.find(id)
              u.update(progress: "finished audio conversion")
              
              #SpeechToText::GoogleS2T.google_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"],data["google_bucket_name"])
              
              SpeechToText::GoogleS2T.set_environment(data["auth_key"])
              SpeechToText::GoogleS2T.google_storage(data["published_file_path"],data["recordID"],data["google_bucket_name"])
              operation_name = SpeechToText::GoogleS2T.create_job(data["recordID"],data["google_bucket_name"])
              
              u.update(progress: "created job with #{u.service}")      
          
              #puts params[0].name
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
              u.update(progress: "waiting on job from #{u.service}")
              
              #SpeechToText::GoogleS2T.google_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"],data["google_bucket_name"])
          
              callback = SpeechToText::GoogleS2T.check_job(operation_name)
              myarray = SpeechToText::GoogleS2T.create_array_google(callback["results"])
          
              u.update(progress: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt(data["published_file_path"],data["recordID"],myarray)
              
              SpeechToText::GoogleS2T.delete_google_storage(data["google_bucket_name"], data["recordID"])
              
              u.update(progress: "done with #{u.service}")
          
              File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")

          #end
      end
    end
    
    class IbmWorker_1
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Caption.find(id)
              u.update(progress: "finished audio conversion")
             #SpeechToText::IbmWatsonS2T.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
          
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
          
             #SpeechToText::IbmWatsonS2T.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
              status = "processing"
              while(status != "completed")
                callback = SpeechToText::IbmWatsonS2T.check_job(job_id,data["auth_key"])
                status = callback["status"]
                #sleep(300)
              end
          
              myarray = SpeechToText::IbmWatsonS2T.create_array_watson(callback["results"][0])
          
              u.update(progress: "writing subtitle file from #{u.service}")
              SpeechToText::Util.write_to_webvtt(data["published_file_path"],data["recordID"],myarray)
          
              u.update(progress: "done with #{u.service}")
          
              File.delete("#{data["published_file_path"]}/#{data["recordID"]}/#{data["recordID"]}.json")
          
      end
    end
    
    class DeepspeechWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Caption.find(id)
              u.update(progress: "finished audio & started #{u.service} transcription process")
             SpeechToText::MozillaDeepspeechS2T.mozilla_speech_to_text(data["published_file_path"],data["recordID"],data["deepspeech_model_path"])
              
              u.update(progress: "done with #{u.service}")
          
      end
    end
    
    class SpeechmaticsWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Caption.find(id)
              u.update(progress: "finished audio & started #{u.service} transcription process")
             SpeechToText::SpeechmaticsS2T.speechmatics_speech_to_text(data["published_file_path"],data["recordID"],data["userID"],data["auth_key"])
              
              u.update(progress: "done with #{u.service}")
          
      end
    end
end
