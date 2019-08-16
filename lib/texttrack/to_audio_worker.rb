require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require "google/cloud/speech"
require "google/cloud/storage"
require "speech_to_text"
require "sqlite3"
require 'active_record'
rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module WM
  class ToAudioWorker
    include Faktory::Job
    faktory_options retry: 0

    def perform(param_json)
      params = JSON.parse(param_json, :symbolize_names => true)

      if Caption.exists?(record_id: "#{params[:record_id]}")
        u = Caption.find_by(record_id: "#{params[:record_id]}")
        u.update(status: "start_audio_conversion",
                service: "#{params[:provider][:name]}",
                caption_locale: "#{params[:caption_locale]}")
      else
        Caption.create(record_id: "#{params[:record_id]}",
                status: "started_audio_conversion",
                service: "#{params[:provider][:name]}",
                caption_locale: "#{params[:caption_locale]}")
      end

      u = Caption.find_by(record_id: "#{params[:record_id]}")

      audio_type_hash = {
         "ibm" => "wav",
         "google" => "flac",
         "speechmatics" => "mp3",
         "threeplaymedia" => "wav"
      } 
      
      SpeechToText::Util.video_to_audio(
                  video_file_path: "#{params[:recordings_dir]}/#{params[:record_id]}/video",
                  video_name:"video",
                  video_content_type: "mp4",
                  audio_file_path: "#{params[:recordings_dir]}/#{params[:record_id]}",
                  audio_name: params[:record_id],
                  audio_content_type: audio_type_hash[params[:provider][:name]])

      if(params[:provider][:name] === "google")
        WM::GoogleWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "ibm")
        WM::IbmWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "deepspeech")
        WM::DeepspeechWorker.perform_async(params.to_json, u.id);
      elsif(params[:provider][:name] === "speechmatics")
        WM::SpeechmaticsWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "threeplaymedia")
        WM::ThreeplaymediaWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      end
    end
  end
end
