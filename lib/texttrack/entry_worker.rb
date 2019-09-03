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

      default_provider = props["default_provider"]
      recordings_dir = props["recordings_dir"]
      captions_inbox_dir = props["captions_inbox_dir"]
      temp_storage = props["temp_storage"]

      provider_name = default_provider
      unless params[:provider].nil?
        provider_name = params[:provider]
      end

      to_audio_params = {record_id: params[:record_id],
        caption_locale: params[:caption_locale],
        recordings_dir: recordings_dir,
        captions_inbox_dir: captions_inbox_dir,
        temp_storage: temp_storage}

      provider = {name: provider_name}

      if (provider_name == "google")
        provider[:google_bucket_name] = props_keys["providers"][provider_name]["bucket"]
        provider[:auth_file_path] = props_keys["providers"][provider_name]["auth_file_path"]
      elsif (provider_name == 'ibm')
        provider[:google_bucket_name] = props_keys["providers"][provider_name]["bucket"]
        provider[:auth_file_path] = props_keys["providers"][provider_name]["auth_file_path"]
      elsif (provider_name == "speechmatics")
        provider[:userID] = props_keys["providers"][provider_name]["userID"]
        provider[:apikey] = props_keys["providers"][provider_name]["apikey"]
      elsif (provider_name == "threeplaymedia")
        provider[:auth_file_path] = props_keys["providers"][provider_name]["auth_file_path"]
      elsif (provider_name == "deepspeech")
        provider[:auth_file_path] = props_keys["providers"][provider_name]["url"]
      end

      to_audio_params[:provider] = provider

      puts to_audio_params
      WM::ToAudioWorker.perform_async(to_audio_params.to_json)
    end
  end
end
