require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
require "speech_to_text"
require "sqlite3"
ENV['RAILS_ENV'] = "development"
require "./config/environment"

module WM
  class ToAudioWorker
    include Faktory::Job
    faktory_options retry: 0

    def perform(param_json)
      params = JSON.parse(param_json, :symbolize_names => true)

      if Caption.exists?(recordID: "#{params[:record_id]}")
        u = Caption.find_by(recordID: "#{params[:record_id]}")
        u.update(progress: "start_audio_conversion", 
                service: "Do not need provider here.")
      else
        Caption.create(recordID: "#{params[:record_id]}", 
                progress: "started_audio_conversion", 
                service: "Do not need provider here.")
      end
          
      u = Caption.find_by(recordID: "#{params[:record_id]}")

      SpeechToText::Util.video_to_audio(params[:recordings_dir], params[:provider])

      if(params[:provider] === "google")
        WM::GoogleWorker_1.perform_async(data, u.id);
      elsif(params[:provider] === "ibm") 
        WM::IbmWorker_1.perform_async(data, u.id);
      elsif(params[:provider] === "deepspeech") 
        WM::DeepspeechWorker.perform_async(data, u.id);
      elsif(params[:provider] === "speechmatics") 
        WM::SpeechmaticsWorker.perform_async(data, u.id);
      end
    end
  end
end