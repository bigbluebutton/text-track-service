require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
require "speech_to_text"
require "sqlite3"
require_relative "../../app"

module WM
    
    class AudioWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data)
          
          if Progress.exists?(recordID: "#{data["recordID"]}")
              u = Progress.find_by(recordID: "#{data["recordID"]}")
              u.update(progress: "Started audio conversion", service: "#{data["service"]}")
          else
              Progress.create(recordID: "#{data["recordID"]}", progress: "Started audio conversion", service: "#{data["service"]}")
          end
          
          #Progress.find_by(recordID: "#{data["recordID"]}").first_or_create(recordID: "#{data["recordID"]}").update(progress: 'Started audio conversion')
          
          u = Progress.find_by(recordID: "#{data["recordID"]}")
          #Progress.create(recordID: "#{data["recordID"]}", progress: "audio conversion started")
          
          SpeechToText::Util.video_to_audio(data["published_file_path"],data["recordID"],data["service"]);

          if(data["service"] === "google")
            ENV['GOOGLE_APPLICATION_CREDENTIALS'] = "#{data["auth_key"]}";
            WM::GoogleWorker.perform_async(data, u.id);
          elsif(data["service"] === "ibm") 
            WM::IbmWorker.perform_async(data, u.id);
          elsif(data["service"] === "deepspeech") 
            WM::DeepspeechWorker.perform_async(data, u.id);
          elsif(data["service"] === "speechmatics") 
            WM::SpeechmaticsWorker.perform_async(data, u.id);
          end


      end
    end
    
    class GoogleWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          #if(data["service"] === "google")

             #google_speech_to_text 
              u = Progress.find(id)
              u.update(progress: "finished audio & started #{u.service} transcription process")
              
              SpeechToText::GoogleS2T.google_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"],data["google_bucket_name"])
              
              u.update(progress: "done with #{u.service}")

          #end
      end
    end
    
    class IbmWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Progress.find(id)
              u.update(progress: "finished audio & started #{u.service} transcription process")
             SpeechToText::IbmWatsonS2T.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
              
              u.update(progress: "done with #{u.service}")
          
      end
    end
    
    class DeepspeechWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Progress.find(id)
              u.update(progress: "finished audio & started #{u.service} transcription process")
             SpeechToText::MozillaDeepspeechS2T.mozilla_speech_to_text(data["published_file_path"],data["recordID"],data["model_path"])
              
              u.update(progress: "done with #{u.service}")
          
      end
    end
    
    class SpeechmaticsWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          
              
              u = Progress.find(id)
              u.update(progress: "finished audio & started #{u.service} transcription process")
             SpeechToText::SpeechmaticsS2T.speechmatics_speech_to_text(data["published_file_path"],data["recordID"],data["user_id"],data["auth_key"])
              
              u.update(progress: "done with #{u.service}")
          
      end
    end
end
