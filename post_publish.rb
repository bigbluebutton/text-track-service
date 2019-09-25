#!/usr/bin/ruby
# encoding: UTF-8

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

require "trollop"

require File.expand_path('../../../lib/recordandplayback', __FILE__)

opts = Trollop::options do
  opt :meeting_id, "Meeting id to archive", :type => String
end
$meeting_id = opts[:meeting_id]

logger = Logger.new("/var/log/bigbluebutton/post_publish.log", 'weekly' )
logger.level = Logger::INFO
BigBlueButton.logger = logger

$published_files = "/var/bigbluebutton/published/presentation/#{$meeting_id}"
$archived_files = "/var/bigbluebutton/recording/raw/#{$meeting_id}"
$meeting_metadata = BigBlueButton::Events.get_meeting_metadata("/var/bigbluebutton/recording/raw/#{$meeting_id}/events.xml")
$events_xml = "#{$archived_files}/events.xml"
$audio_dir = "#{$archived_files}/audio"
#$published_files_video = "/var/bigbluebutton/published/presentation/#{$meeting_id}/video"
#$scripts = "/usr/local/bigbluebutton/core/scripts/post_publish"

############################CUSTOM SCRIPT STARTS HERE#######################################
require "rest-client"
require 'yaml'
#[{"localeName": "English (United States)", "locale": "en-US"}]

#response = RestClient::Request.execute(
    #method: :get,
    #url:    "http://localhost:4000/caption/#{$meeting_id}/en-US",
#)

bbb_props = YAML.load_file('../bigbluebutton.yml')

site = bbb_props['playback_host']
secret = bbb_props['shared_secret']
kind = "subtitles"
lang = "en_US"
label = "English"

#original_filename = "captions_en-US.vtt"
#temp_filename = "#{recordID}-#{current_time}-track.txt"
request = "putRecordingTextTrackrecordID=#{meeting_id}&kind=#{kind}&lang=#{lang}&label=#{label}"
request = request + secret
checksum = Digest::SHA1.hexdigest(request)

RestClient.get "http://localhost:4000/caption/#{meeting_id}/en-US", {:params => {:site => "https://#{site}", :checksum => "#{checksum}"}}

#response = RestClient.get 'http://localhost:3000/caption/#{$meeting_id}/en-US'
if(response.code != 200)
  BigBlueButton.logger.info("#{response.code} error")
end
#system("curl http://localhost:3000/caption/#{$meeting_id}/en-US")



exit 0



