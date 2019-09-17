require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'
require 'sqlite3'
rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTP
  class PlaybackPutJob
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    def perform(params_json, id, temp_track_vtt, temp_track_json)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: 'playback work started')
      end
      
      inbox_dir = "#{params[:captions_inbox_dir]}/inbox"
      playback_dir = "#{params[:playback_dir]}/#{params[:record_id]}"
        
      FileUtils.cp("#{inbox_dir}/#{temp_track_vtt}",
              "#{playback_dir}/#{params[:record_id]}.vtt",
              verbose: true)
        
      SpeechToText::Util.captions_json(
        file_path: "#{params[:playback_dir]}",
        file_name: "captions.json",
        localeName: "English (United States)",
        locale: params[:caption_locale]
      )
      
      #FileUtils.remove_dir(temp_dir.to_s)
      
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "done with #{u.service}")
      end

    end
  end

end
