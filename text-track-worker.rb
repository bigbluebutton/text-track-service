require 'logger'
require './lib/texttrack'

#log_dir = "/var/log/text-track-service"
log_dir = "samples"
logger = Logger.new(STDOUT)
#logger = Logger.new("#{log_dir}/text-track-worker.log", 'daily', 14)
logger.level = Logger::INFO

TextTrack.logger = logger
