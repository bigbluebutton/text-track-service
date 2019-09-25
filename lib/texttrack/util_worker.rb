require 'connection_pool'
require 'faktory'

module TTS
  class UtilWorker # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params) # rubocop:disable Metrics/CyclomaticComplexity

      data = JSON.load params
      record_id = data['record_id']
      temp_dir = data['temp_dir']
      temp_track_vtt = data['temp_track_vtt']
      temp_track_json = data['temp_track_json']
      inbox = data['inbox']
      myarray = data['myarray']
      current_time = data['current_time']
      caption_locale = data['caption_locale']
      id = data['database_id']

      u = Caption.find(id)
      ActiveRecord::Base.connection_pool.with_connection do
        # u = Caption.find(id)
        u.update(status: "writing subtitle file from #{u.service}")
      end

      SpeechToText::Util.write_to_webvtt(
        vtt_file_path: "#{temp_dir}",
        vtt_file_name: "#{temp_track_vtt}",
        myarray: myarray
      )

      SpeechToText::Util.recording_json(
        file_path: temp_dir.to_s,
        record_id: record_id,
        timestamp: current_time,
        language: data[:caption_locale]
      )

      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "done with #{u.service}")
      end

      FileUtils.mv("#{temp_dir}/#{temp_track_vtt}",
                   inbox,
                   verbose: true)
      # , :force => true)

      FileUtils.mv("#{temp_dir}/#{temp_track_json}",
                   inbox,
                   verbose: true)
      # , :force => true)

      FileUtils.remove_dir(temp_dir.to_s)

    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
