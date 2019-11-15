# frozen_string_literal: true

require 'faktory_worker_ruby'
require 'connection_pool'
require 'faktory'
require 'securerandom'

rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  # rubocop:disable Style/Documentation
  class RepairWorker
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform()
        failed_jobs = ''
      ActiveRecord::Base.connection_pool.with_connection do
        failed_jobs = Caption.where.not('status LIKE ?', 'uploaded%')
      end

      failed_jobs.each do |f|
        puts "#{f.record_id} --> #{f.status} --> #{f.bbb_url} --> #{f.bbb_checksum} --> #{f.kind} --> #{f.label} --> #{f.caption_locale} --> #{f.service}"
        caption_job = { record_id: f.record_id,
                        caption_locale: f.caption_locale,
                        provider: f.service,
                        bbb_url: f.bbb_url,
                        bbb_checksum: f.bbb_checksum,
                        kind: f.kind,
                        label: f.label }
        
        TTS::EntryWorker.perform_async(caption_job.to_json)                        
      end
      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Style/Documentation

  # rubocop:disable Style/Documentation
      #                                  temp_track_vtt,
      #                                  temp_track_json,
      #                                  inbox)
end

