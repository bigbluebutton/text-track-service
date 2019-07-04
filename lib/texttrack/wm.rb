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
              u.update(progress: "Started audio conversion")
          else
              Progress.create(recordID: "#{data["recordID"]}", progress: "Started audio conversion")
          end
          
          #Progress.find_by(recordID: "#{data["recordID"]}").first_or_create(recordID: "#{data["recordID"]}").update(progress: 'Started audio conversion')
          
          u = Progress.find_by(recordID: "#{data["recordID"]}")
          #Progress.create(recordID: "#{data["recordID"]}", progress: "audio conversion started")
          
          SpeechToText::Util.video_to_audio(data["published_file_path"],data["recordID"]);

          if(data["service"] === "google")
            ENV['GOOGLE_APPLICATION_CREDENTIALS'] = "#{data["auth_key"]}";
            WM::GoogleWorker.perform_async(data, u.id);
          elsif(data["service"] === "ibm") 
            WM::IbmWorker.perform_async(data, u.id);   
          end


      end
    end
    
    class GoogleWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          if(data["service"] === "google")

             #google_speech_to_text 
              u = Progress.find(id)
              u.update(progress: "finished audio & started #{data["service"]} transcription process")
              
              SpeechToText::BBBGoogleCaptions.google_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"],data["google_bucket_name"])
              
              u.update(progress: "done with #{data["service"]}")

              #dice = GamesDice.create '4d6+3'
              #puts dice.roll  #  => 17 (e.g.)
          end
      end
    end
    
    class IbmWorker
      include Faktory::Job
      faktory_options retry: 0

      def perform(data, id)
          if(data["service"] === "ibm")
              
              u = Progress.find(id)
              u.update(progress: "finished audio & started #{data["service"]} transcription process")
             SpeechToText::BBBIbmCaptions.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
              
              u.update(progress: "done with #{data["service"]}")
          end
      end
    end
    
    
end
