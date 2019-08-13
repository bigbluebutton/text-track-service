# encoding: UTF-8

require 'connection_pool'
require 'faktory'

module WM
  class EntryWorker
    include Faktory::Job
    faktory_options retry: 5

    def perform(params_json)
      params = JSON.parse(params_json, :symbolize_names => true)

      TextTrack.logger.info("Processing analytics for #{params[:record_id]}")
      props = YAML::load_file('settings.yaml')

      props_keys = YAML::load_file('credentials.yaml')

      apikey = props_keys["providers"][props["default_provider"]]["apikey"]

      default_provider = props["default_provider"]
      recordings_dir = props["recordings_dir"]
      captions_inbox_dir = props["captions_inbox_dir"]



      to_audio_params = {record_id: params[:record_id],
        caption_locale: params[:caption_locale],
        provider: default_provider,
        auth_key: apikey,
        recordings_dir: recordings_dir,
        captions_inbox_dir: captions_inbox_dir}


      if (props["default_provider"] == "google")
         to_audio_params.merge!(google_bucket_name: props_keys["providers"][props["default_provider"]]["bucket"])
      elsif(props["default_provider"] == "speechmatics")
          to_audio_params.merge!(user_id: props_keys["providers"][props["default_provider"]]["user_id"])
      end

      puts to_audio_params
      WM::ToAudioWorker.perform_async(to_audio_params.to_json)
    end
  end
end
