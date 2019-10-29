# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'google/cloud/speech'
require 'google/cloud/storage'
require 'speech_to_text'

require 'active_record'
rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  class ToAudioWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(param_json) # rubocop:disable Metrics/CyclomaticComplexity
      params = JSON.parse(param_json, symbolize_names: true)
      u = nil
      # needed as activerecord leaves connection open when worker dies
      
      ActiveRecord::Base.connection_pool.with_connection do
        if Caption.exists?(record_id: (params[:record_id]).to_s)
          u = Caption.find_by(record_id: (params[:record_id]).to_s)
          u.update(status: 'start_audio_conversion',
                   service: (params[:provider][:name]).to_s,
                   caption_locale: (params[:caption_locale]).to_s)
        else
          Caption.create(record_id: (params[:record_id]).to_s,
                         status: 'started_audio_conversion',
                         service: (params[:provider][:name]).to_s,
                         caption_locale: (params[:caption_locale]).to_s)
        end

        u = Caption.find_by(record_id: (params[:record_id]).to_s)
      end

      audio_type_hash = {
        'ibm' => 'mp3',
        'google' => 'flac',
        'speechmatics' => 'mp3',
        'threeplaymedia' => 'mp3',
        'deepspeech' => 'wav'
      }

      audio_type = audio_type_hash[params[:provider][:name]]

      final_dest_dir = "#{params[:storage_dir]}/#{params[:record_id]}"
      audio_file = "audio.#{audio_type}"
      
      unless Dir.exist?(final_dest_dir)
        FileUtils.mkdir_p(final_dest_dir)
        FileUtils.chmod('u=wrx,g=wrx,o=r', final_dest_dir)
      end

      unless File.exist?("#{final_dest_dir}/#{audio_file}")
        SpeechToText::Util.video_to_audio(
          video_file_path: final_dest_dir.to_s,
          video_name: 'audio_temp',
          video_content_type: 'wav',
          audio_file_path: final_dest_dir.to_s,
          audio_name: 'audio',
          audio_content_type: audio_type
        )
      end

      # rubocop:disable Style/CaseEquality
      if params[:provider][:name] === 'google'
        # rubocop:enable Style/CaseEquality
        TTS::GoogleCreateJob.perform_async(params.to_json,
                                           u.id,
                                           audio_type)
      # rubocop:disable Style/CaseEquality
      elsif params[:provider][:name] === 'ibm'
        # rubocop:enable Style/CaseEquality
        TTS::IbmCreateJob.perform_async(params.to_json,
                                        u.id,
                                        audio_type)
      # rubocop:disable Style/CaseEquality
      elsif params[:provider][:name] === 'deepspeech'
        # rubocop:enable Style/CaseEquality
        TTS::DeepspeechCreateJob.perform_async(params.to_json,
                                               u.id,
                                               audio_type)
      # rubocop:disable Style/CaseEquality
      elsif params[:provider][:name] === 'speechmatics'
        # rubocop:enable Style/CaseEquality
        TTS::SpeechmaticsCreateJob.perform_async(params.to_json,
                                                 u.id,
                                                 audio_type)
      # rubocop:disable Style/CaseEquality
      elsif params[:provider][:name] === 'threeplaymedia'
        # rubocop:enable Style/CaseEquality
        TTS::ThreeplaymediaCreateJob.perform_async(params.to_json,
                                                   u.id,
                                                   audio_type)
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
