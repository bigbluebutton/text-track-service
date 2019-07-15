# encoding: UTF-8

require 'connection_pool'
require 'faktory'

module WM
  class EntryWorker
    include Faktory::Job
    faktory_options retry: 5

    def perform(record_id)
      TextTrack.logger.info("Processing analytics for #{record_id}")
      props = YAML::load_file('settings.yaml')

      default_provider = props["default_provider"]
      recordings_dir = props["recordings_dir"]

      params = {record_id: record_id, 
        provider: default_provider, 
        recordings_dir: recordings_dir}

      WM::AudioWorker.perform_async(params.to_json)
    end
  end
end