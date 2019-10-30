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

meeting_id = opts[:meeting_id]

logger = Logger.new('/var/log/bigbluebutton/post_publish.log', 'weekly')
logger.level = Logger::INFO
BigBlueButton.logger = logger

published_files = "/var/bigbluebutton/published/presentation/#{meeting_id}"
archived_files = "/var/bigbluebutton/recording/raw/#{meeting_id}"
meeting_metadata = BigBlueButton::Events.get_meeting_metadata("/var/bigbluebutton/recording/raw/#{meeting_id}/events.xml")
events_xml = "#{archived_files}/events.xml"
audio_dir = "#{archived_files}/audio"
#published_files_video = "/var/bigbluebutton/published/presentation/#{$meeting_id}/video"
#scripts = "/usr/local/bigbluebutton/core/scripts/post_publish"

############################CUSTOM SCRIPT STARTS HERE#######################################
require "rest-client"
require 'yaml'
require "speech_to_text"
#[{"localeName": "English (United States)", "locale": "en-US"}]


# response = RestClient::Request.execute(
# method: :get,
# url:    "http://localhost:4000/caption/#{$meeting_id}/en-US",
# )

temp_storage = "/var/bigbluebutton/captions"

final_dest_dir = "#{temp_storage}/#{meeting_id}"
audio_file = "#{meeting_id}.wav"
unless Dir.exist?(final_dest_dir)
  FileUtils.mkdir_p(final_dest_dir)
  FileUtils.chmod('u=wrx,g=wrx,o=r', final_dest_dir)
end

unless File.exist?("#{final_dest_dir}/#{audio_file}")
SpeechToText::Util.video_to_audio(
  video_file_path: "#{published_files}/video",
  video_name: 'webcams',
  video_content_type: 'webm',
  audio_file_path: final_dest_dir.to_s,
  audio_name: audio,
  audio_content_type: "wav"
)
end

bbb_props = YAML.load_file('/usr/local/bigbluebutton/core/scripts/bigbluebutton.yml')

site = bbb_props['playback_host']
secret = bbb_props['shared_secret']
kind = "subtitles"
lang = "en_US"
label = "English"
request = "putRecordingTextTrackrecordID=#{meeting_id}&kind=#{kind}&lang=#{lang}&label=#{label}"
request += secret
checksum = Digest::SHA1.hexdigest(request)

#response = RestClient.get "http://localhost:4000/caption/#{meeting_id}/en-US", {:params => {:site => "https://#{site}", :checksum => "#{checksum}"}}

request = RestClient::Request.new(
    method: :get, 
    url: "http://localhost:4000/caption/#{meeting_id}/en-US",
    payload: { :file => File.open("#{temp_storage}/#{meeting_id}/audio.wav", 'rb'), :bbb_url => "http://#{site}", :bbb_checksum => "#{checksum}", :kind => "#{kind}", :label => "#{label}" }
)
response = request.execute

if(response.code != 200)
  BigBlueButton.logger.info("#{response.code} error")
end

exit 0
