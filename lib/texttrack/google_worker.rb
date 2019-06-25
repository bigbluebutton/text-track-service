require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
#require "games_dice"
require "speech_to_text"
#require_relative "../../helper.rb"

class GoogleWorker
  include Faktory::Job
  faktory_options retry: 0

  def perform(data)
      if(data["service"] === "google")
         
         #google_speech_to_text 
          SpeechToText::BBBGoogleCaptions.google_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"],data["google_bucket_name"])
          
          #dice = GamesDice.create '4d6+3'
          #puts dice.roll  #  => 17 (e.g.)
      end
  end
end
