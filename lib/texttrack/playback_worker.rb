# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'

rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  class PlaybackWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1
    def perform(params_json, temp_track_vtt, temp_track_json, _inbox_dir)
      params = JSON.parse(params_json, symbolize_names: true)

      playback_job = { vtt_file: temp_track_vtt,
                       json_file: temp_track_json }

      playback_job = params.merge(playback_job)

      props = YAML.safe_load(File.open('settings.yaml'))
      playback_list_namespace = props['playback_list_namespace']

      playback_redis =
        Redis::Namespace.new(playback_list_namespace, redis: Redis.new)
      playback_redis.rpush('playback_job', playback_job.to_json)
    end
  end
end
