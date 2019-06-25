require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"

#require_relative "../../helper.rb"

class IbmWorker
  include Faktory::Job
  faktory_options retry: 0

  def perform(data)
      if(data["service"] === "ibm")
         SpeechToText::BBBIbmCaptions.ibm_speech_to_text(data["published_file_path"],data["recordID"],data["auth_key"])
      end
  end
end
