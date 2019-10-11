# frozen_string_literal: true

require 'logger'
require './lib/texttrack'
require 'speech_to_text'

props = YAML.load_file('settings.yaml')

if props['log_to_file']
  log_dir = '/var/log/text-track-service'
  logger = Logger.new("#{log_dir}/text-track-service.log", 'daily', 14)
else
  logger = Logger.new(STDOUT)
end

TextTrack.logger = logger

redis = if ENV['REDIS_URL'].nil?
          Redis.new
        else
          Redis.new(url: ENV['REDIS_URL'])
        end

RECORDINGS_EDIT_JOB_LIST_KEY = props['redis_edit_jobs_list_key']
puts RECORDINGS_EDIT_JOB_LIST_KEY
num_entries = redis.llen(RECORDINGS_EDIT_JOB_LIST_KEY)
puts "num_edit_entries  = #{num_entries}"
loop do
  # for i in 1..num_entries do
  _list, element = redis.blpop(RECORDINGS_EDIT_JOB_LIST_KEY)
  TextTrack.logger.info("Processing analytics for recording #{element}")
  job_entry = JSON.parse(element)
  puts job_entry
  TTS::CallbackWorker.perform_async(job_entry.to_json)
end
