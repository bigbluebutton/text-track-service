# frozen_string_literal: true

require 'connection_pool'
require 'faktory'

module TTS
  class EntryWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1

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
                          label: params[:label],
                          start_time: params[:start_time],
                          end_time: params[:end_time]
                         }

      provider = { name: provider_name }
      to_audio_params[:provider] = provider

      if provider_name == 'google'
        provider[:google_bucket_name] =
          props_keys['providers'][provider_name]['bucket']
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['auth_file_path']
        TTS::GoogleCreateJob.to_audio(to_audio_params.to_json)  

      elsif provider_name == 'ibm'
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['auth_file_path']
          TTS::IbmCreateJob.to_audio(to_audio_params.to_json)

      elsif provider_name == 'speechmatics'
        provider[:userID] =
          props_keys['providers'][provider_name]['userID']
        provider[:apikey] =
          props_keys['providers'][provider_name]['apikey']
        TTS::SpeechmaticsCreateJob.to_audio(to_audio_params.to_json)

      elsif provider_name == 'amazon'
        provider[:bucket] =
          props_keys['providers'][provider_name]['bucket']
        provider[:region] =
          props_keys['providers'][provider_name]['region']
        provider[:key] =
          props_keys['providers'][provider_name]['key']  
        provider[:secret] =
          props_keys['providers'][provider_name]['secret']  
        TTS::AmazonCreateJob.to_audio(to_audio_params.to_json)        

      elsif provider_name == 'threeplaymedia'
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['auth_file_path']
        TTS::ThreeplaymediaCreateJob.to_audio(to_audio_params.to_json)

      elsif provider_name == 'deepspeech'
        provider[:auth_file_path] =
          props_keys['providers'][provider_name]['url']
        provider[:apikey] =
          props_keys['providers'][provider_name]['apikey']
          TTS::DeepspeechCreateJob.to_audio(to_audio_params.to_json)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
