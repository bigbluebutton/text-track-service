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
                service: "Do not need provider here.",
                caption_locale: "#{params[:caption_locale]}")
      else
        Caption.create(record_id: "#{params[:record_id]}",
                status: "started_audio_conversion",
                service: "Do not need provider here.",
                caption_locale: "#{params[:caption_locale]}")
      end

      u = Caption.find_by(record_id: "#{params[:record_id]}")

      SpeechToText::Util.video_to_audio(params[:recordings_dir], params[:provider])
        
      if(u.service == "ibm")
              SpeechToText::Util.video_to_audio(
                  video_file_path: "#{params[:recordings_dir]}/video",
                  video_name:"video",
                  video_content_type: "mp4",
                  audio_file_path: params[:recordings_dir],
                  audio_name: params[:record_id],
                  audio_content_type: "wav") 
          elsif(u.service == "google")
              SpeechToText::Util.video_to_audio(
                  video_file_path: "#{params[:recordings_dir]}/video",
                  video_name:"video",
                  video_content_type: "mp4",
                  audio_file_path: params[:recordings_dir],
                  audio_name: params[:record_id],
                  audio_content_type: "wav")
          elsif(u.service == "speechmatics")
              SpeechToText::Util.video_to_audio(
                  video_file_path: "#{params[:recordings_dir]}/video",
                  video_name:"video",
                  video_content_type: "mp4",
                  audio_file_path: params[:recordings_dir],
                  audio_name: params[:record_id],
                  audio_content_type: "mp3")
          else
              SpeechToText::Util.video_to_audio(
                  video_file_path: "#{params[:recordings_dir]}/video",
                  video_name:"video",
                  video_content_type: "mp4",
                  audio_file_path: params[:recordings_dir],
                  audio_name: params[:record_id],
                  audio_content_type: "wav");
          end

      if(params[:provider] === "google")
        WM::GoogleWorker_1.perform_async(params.to_json, u.id);
      elsif(params[:provider] === "ibm")
        WM::IbmWorker_1.perform_async(params.to_json, u.id);
      elsif(params[:provider] === "deepspeech")
        WM::DeepspeechWorker.perform_async(params.to_json, u.id);
      elsif(params[:provider] === "speechmatics")
        WM::SpeechmaticsWorker_1.perform_async(params.to_json, u.id);
      end
    end
  end
end
