
require 'logger'
require './lib/texttrack'
require 'speech_to_text'

props = YAML::load_file('settings.yaml')

if props['log_to_file']
  log_dir = "/var/log/text-track-service"
  logger = Logger.new("#{log_dir}/text-track-service.log", 'daily', 14)
else
  logger = Logger.new(STDOUT)
end

TextTrack.logger = logger

#
# Connect to Redis
#
redis_host = props['redis_host']
redis_port = props['redis_port']
redis_password = props['redis_password']

if redis_password.nil?
  redis = Redis.new(:host => redis_host, :port => redis_port)
else
  redis = Redis.new(:host => redis_host, :port => redis_port, :password => redis_password)
end

RECORDINGS_JOB_LIST_KEY = props["redis_jobs_list_key"]

#num_entries = redis.llen(RECORDINGS_JOB_LIST_KEY)
loop do
#for i in 1..num_entries do
  #list, element = redis.lpop(CALLBACK_JOB_LIST_KEY, :timeout => 0)
  #element = redis.lpop(RECORDINGS_JOB_LIST_KEY)
  element = redis.blpop(RECORDINGS_JOB_LIST_KEY)
  TextTrack.logger.info("Processing analytics for recording #{element}")
  job_entry = JSON.parse(element)

  WM::EntryWorker.perform_async(job_entry.to_json)
end
