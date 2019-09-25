# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#

path = File.expand_path(File.join(File.dirname(__FILE__), '../lib'))
$LOAD_PATH << path

require 'texttrack/util'
require 'texttrack/entry_worker'
require 'texttrack/google_worker'
require 'texttrack/ibm_worker'
require 'texttrack/deepspeech_worker'
require 'texttrack/speechmatics_worker'
require 'texttrack/threeplaymedia_worker'
require 'texttrack/to_audio_worker'
require 'texttrack/util_worker'
require 'texttrack/callback_worker'
require 'texttrack/playback_worker'

module TextTrack # rubocop:disable Style/Documentation
  def self.logger=(log)
    @logger = log
  end

  def self.logger
    return @logger if @logger

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    @logger = logger
  end
end
