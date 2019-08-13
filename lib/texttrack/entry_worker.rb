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
        
      props_keys = YAML::load_file('credentials.yaml')
        
      apikey = props_keys["providers"][props["default_provider"]]["apikey"]

      default_provider = props["default_provider"]
      recordings_dir = props["recordings_dir"]
      captions_inbox_dir = props["captions_inbox_dir"]
        
      record_id = JSON.parse(record_id)
        
      params = {record_id: record_id["record_id"],
        caption_locale: record_id["caption_locale"],
        provider: default_provider,
        auth_key: apikey,
        recordings_dir: recordings_dir,
        captions_inbox_dir: captions_inbox_dir}
        
      if(props["default_provider"] == "google") 
         params.merge!(google_bucket_name: props_keys["providers"][props["default_provider"]]["bucket"]) 
      elsif(props["default_provider"] == "speechmatics")
          params.merge!(userID: props_keys["providers"][props["default_provider"]]["userID"])
      end
      WM::ToAudioWorker.perform_async(params.to_json)
    end
  end
end