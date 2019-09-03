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
         "ibm" => "mp3",
         "google" => "mp3",
         "speechmatics" => "mp3",
         "threeplaymedia" => "mp3",
         "deepspeech" => "wav"
      }
        
      final_dest_dir = "#{params[:temp_storage]}/#{params[:record_id]}"
      unless Dir.exist?(final_dest_dir)
          FileUtils.mkdir_p(final_dest_dir)
          FileUtils.chmod("u=wrx,g=wrx,o=r", final_dest_dir)
      end
      
      SpeechToText::Util.video_to_audio(
                  video_file_path: "#{params[:recordings_dir]}/#{params[:record_id]}/video",
                  video_name:"webcams",
                  video_content_type: "webm",
                  audio_file_path: "#{params[:temp_storage]}/#{params[:record_id]}",
                  audio_name: params[:record_id],
                  audio_content_type: audio_type_hash[params[:provider][:name]])

      if(params[:provider][:name] === "google")
        WM::GoogleWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "ibm")
        WM::IbmWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "deepspeech")
        WM::DeepspeechWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "speechmatics")
        WM::SpeechmaticsWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      elsif(params[:provider][:name] === "threeplaymedia")
        WM::ThreeplaymediaWorker_createJob.perform_async(params.to_json, u.id, audio_type_hash[params[:provider][:name]]);
      end
    end
  end
end
