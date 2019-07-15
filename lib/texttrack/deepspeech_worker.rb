require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "speech_to_text"
require "sqlite3"
ENV['RAILS_ENV'] = "development"
require "./config/environment"

module WM        
  class DeepspeechWorker
    include Faktory::Job
    faktory_options retry: 0

    def perform(data, id)
      u = Caption.find(id)
      u.update(progress: "finished audio & started #{u.service} transcription process")

      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?
      SpeechToText::MozillaDeepspeechS2T.mozilla_speech_to_text(data["published_file_path"],data["recordID"],data["deepspeech_model_path"])
              
      u.update(progress: "done with #{u.service}")
          
    end
  end
end