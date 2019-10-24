# frozen_string_literal: true

require 'connection_pool'
require 'faktory'

module TTS
  class EntryWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json) # rubocop:disable Metrics/CyclomaticComplexity
      params = JSON.parse(params_json, symbolize_names: true)

      TextTrack.logger.info("Processing analytics for #{params[:record_id]}")
      props = YAML.load_file('settings.yaml')

      props_keys = YAML.load_file('credentials.yaml')

      default_provider = props['default_provider']
      storage_dir = props['storage_dir']

      provider_name = default_provider
      provider_name = params[:provider] unless params[:provider].nil?

      to_audio_params = { record_id: params[:record_id],
                          caption_locale: params[:caption_locale],
                          storage_dir: storage_dir,
                          bbb_url: params[:bbb_url],
                          bbb_checksum: params[:bbb_checksum],
                          kind: params[:kind],
                          label: params[:label]
                         }

      provider = { name: provider_name }

      if provider_name == 'google'
        provider[:google_bucket_name] =
          props_keys['providers'][provider_name]['bucket']
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['auth_file_path']
      elsif provider_name == 'ibm'
        provider[:google_bucket_name] =
          props_keys['providers'][provider_name]['bucket']
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['auth_file_path']
      elsif provider_name == 'speechmatics'
        provider[:userID] =
          props_keys['providers'][provider_name]['userID']
        provider[:apikey] =
          props_keys['providers'][provider_name]['apikey']
      elsif provider_name == 'threeplaymedia'
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['auth_file_path']
      elsif provider_name == 'deepspeech'
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['url']
      end

      to_audio_params[:provider] = provider

      # puts to_audio_params
      TTS::ToAudioWorker.perform_async(to_audio_params.to_json)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
