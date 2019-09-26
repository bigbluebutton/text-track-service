#!/usr/bin/ruby
# frozen_string_literal: true

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; either version 3.0 of the License, or (at your option)
# any later version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
#

require 'trollop'

require File.expand_path('../../lib/recordandplayback', __dir__)

opts = Trollop.options do
  opt :meeting_id, 'Meeting id to archive', type: String
end
$meeting_id = opts[:meeting_id] # rubocop:disable Style/GlobalVars

logger = Logger.new('/var/log/bigbluebutton/post_publish.log', 'weekly')
logger.level = Logger::INFO
BigBlueButton.logger = logger

# rubocop:disable Style/GlobalVars
$published_files = "/var/bigbluebutton/published/presentation/#{$meeting_id}"
# rubocop:enable Style/GlobalVars
# rubocop:disable Style/GlobalVars
$archived_files = "/var/bigbluebutton/recording/raw/#{$meeting_id}"
# rubocop:enable Style/GlobalVars
# rubocop:disable Style/GlobalVars
$meeting_metadata = BigBlueButton::Events.get_meeting_metadata("/var/bigbluebutton/recording/raw/#{$meeting_id}/events.xml")
# rubocop:enable Style/GlobalVars
$events_xml = "#{$archived_files}/events.xml" # rubocop:disable Style/GlobalVars
$audio_dir = "#{$archived_files}/audio" # rubocop:disable Style/GlobalVars
# $published_files_video = "/var/bigbluebutton/published/presentation/#{$meeting_id}/video"
# $scripts = "/usr/local/bigbluebutton/core/scripts/post_publish"

# ###########################CUSTOM SCRIPT STARTS HERE#######################################
require 'rest-client'
require 'yaml'
# [{"localeName": "English (United States)", "locale": "en-US"}]

# response = RestClient::Request.execute(
# method: :get,
# url:    "http://localhost:4000/caption/#{$meeting_id}/en-US",
# )

bbb_props = YAML.load_file('../bigbluebutton.yml')

site = bbb_props['playback_host']
secret = bbb_props['shared_secret']
kind = 'subtitles'
lang = 'en_US'
label = 'English'

# original_filename = "captions_en-US.vtt"
# temp_filename = "#{recordID}-#{current_time}-track.txt"
request = "putRecordingTextTrackrecordID=#{meeting_id}&kind=#{kind}&lang=#{lang}&label=#{label}"
request += secret
checksum = Digest::SHA1.hexdigest(request)

RestClient.get "http://localhost:4000/caption/#{meeting_id}/en-US", params: { site: "https://#{site}", checksum: checksum.to_s }

# response = RestClient.get 'http://localhost:3000/caption/#{$meeting_id}/en-US'
BigBlueButton.logger.info("#{response.code} error") if response.code != 200
# system("curl http://localhost:3000/caption/#{$meeting_id}/en-US")

exit 0
